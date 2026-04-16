import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/migration_runner.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/repository_service.dart';
import 'package:good_bad_board/routes.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/theme.dart';
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
    // PersistentSetting first: sharedPreference must be set before any widget
    // reads it — including MyApp, which is rendered on FutureBuilder completion.
    await PersistentSetting.instance.initialize();

    // RepositoryService opens the SQLite DB (includes sqfliteFfiInit for Windows)
    await RepositoryService.instance.initialize();

    // One-time silent migration: JSON → SQLite (idempotent; throws on failure)
    await MigrationRunner.run(
      RepositoryService.instance.rootPath,
      RepositoryService.instance.db,
    );

    // Sequential: GameRepository depends on PlayerRepository cache being populated
    await PlayerRepository.instance.initialize();
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
          if (snapshot.hasError) {
            debugPrint(snapshot.error!.toString());
            return const Center(
              child: CircularProgressIndicator(),
            );
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
