import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/data_root.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/repository/session_template_repository.dart';
import 'package:good_bad_board/routes.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppLoader(dataRoot: DataRoot.production()));
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key, required this.dataRoot});

  /// Where the JSON data files are. Required, so a caller cannot reach the
  /// production directory by accident.
  final DataRoot dataRoot;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late final Future completer;

  /// The data folder, once known. Shown on the error screen.
  String? _dataPath;

  Future<void> loading() async {
    await PersistentSetting.instance.initialize();

    final rootDir = await widget.dataRoot.resolve();
    _dataPath = rootDir;
    PlayerRepository.instance = await PlayerRepository.initialize(
      rootDir: rootDir,
    );
    // Game rosters resolve through PlayerRepository.instance lazily (see
    // Game.players), so PlayerRepository must be initialized first.
    GameRepository.instance = await GameRepository.initialize(rootDir: rootDir);
    SessionLogRepository.instance = await SessionLogRepository.initialize(
      rootDir: rootDir,
    );
    PendingRegistrationRepository.instance =
        await PendingRegistrationRepository.initialize(rootDir: rootDir);
    SessionTemplateRepository.instance =
        await SessionTemplateRepository.initialize(rootDir: rootDir);
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
          if (snapshot.hasError) {
            debugPrint(snapshot.error!.toString());
            // Show a plain error and write nothing: a half-loaded app
            // could overwrite good data (PERSISTENCE.md §3.1).
            return _LoadErrorApp(path: _dataPath ?? '?');
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyApp();
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

/// Shown when start-up loading fails. It has no router and no providers.
class _LoadErrorApp extends StatelessWidget {
  const _LoadErrorApp({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.app_load_error(path),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select(
      (PersistentSetting persistentSetting) => persistentSetting.getLanguage(),
    );
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightThemeFor(locale),
      locale: locale,
      darkTheme: darkTheme,
      // The redesign defines a light palette only, and most widgets use
      // AppColors directly. A dark system theme changed only the Material
      // defaults, for example white text in light text fields.
      themeMode: ThemeMode.light,
    );
  }
}
