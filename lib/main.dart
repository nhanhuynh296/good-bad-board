import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/repository_service.dart';
import 'package:good_bad_board/routes.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late final Future completer;

  Future<void> loading() async {
    await Future.wait([
      RepositoryService.instance.initialize(),
      PersistentSetting.instance.initialize(),
    ]);

    await PlayerRepository.instance.initialize();
    // Depends on PlayerRepository to initialize first
    await GameRepository.instance.initialize();
  }

  @override
  void initState() {
    super.initState();
    completer = loading();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: PersistentSetting.instance),
        ChangeNotifierProvider(create: (_) => GameData()),
        ChangeNotifierProvider(create: (_) => TimerData()),
      ],
      child: FutureBuilder(
        future: completer,
        builder: (context, snapshot) {
          if (snapshot.hasError) debugPrint(snapshot.error.toString());
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyApp();
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: Stack(
          children: [if (child != null) child, const ScreenSizeOverlay()],
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 576, name: 'xs'),
          const Breakpoint(start: 577, end: 768, name: 'sm'),
          const Breakpoint(start: 769, end: 992, name: 'md'),
          const Breakpoint(start: 993, end: 1200, name: 'lg'),
          const Breakpoint(start: 1201, end: 1400, name: 'xl'),
          const Breakpoint(start: 1401, end: double.infinity, name: 'xxl'),
        ],
      ),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      locale: context.select(
        (PersistentSetting persistentSetting) =>
            persistentSetting.getLanguage(),
      ),
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}

class ScreenSizeOverlay extends StatefulWidget {
  const ScreenSizeOverlay({super.key});

  @override
  State<ScreenSizeOverlay> createState() => _ScreenSizeOverlayState();
}

class _ScreenSizeOverlayState extends State<ScreenSizeOverlay>
    with SingleTickerProviderStateMixin {
  Size? _lastSize;
  double _opacity = 0.0;

  void _onSizeChanged(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;

    setState(() {
      _opacity = 1.0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _opacity = 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _onSizeChanged(size);

    if (_opacity == 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: Material(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)} == ${ResponsiveBreakpoints.of(context).breakpoint.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
