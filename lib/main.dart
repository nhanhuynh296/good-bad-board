import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/routes.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
    await PersistentSetting.instance.initialize();

    // A test that already pointed the repositories at a sandbox (or a
    // second AppLoader mount in the same process) must not be clobbered by
    // a real getApplicationDocumentsDirectory() call here — skip if
    // PlayerRepository.instance is already set.
    try {
      PlayerRepository.instance;
      return;
    } on Error {
      // Accessing an unassigned `late` field throws LateInitializationError,
      // which isn't a catchable type in this SDK — not yet constructed,
      // fall through and initialize for real.
    }

    final rootDir = (await getApplicationDocumentsDirectory()).path;
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
          if (snapshot.hasError) debugPrint(snapshot.error!.toString());
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
