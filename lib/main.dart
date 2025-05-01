import 'package:flutter/material.dart';
import 'package:good_bad_board/dto/player.dart';
import 'package:good_bad_board/dto/repository_service.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FutureBuilder(
      future: loading(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => GameData()),
            ChangeNotifierProvider(create: (_) => TimerData()),
          ],
          child: const MyApp(),
        );
      },
    ),
  );
}

Future<void> loading() async {
  await RepositoryService.instance.initialize();

  Future.wait([PlayerRepository.instance.initialize()]);

  return;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const LandingPage(),
    );
  }
}
