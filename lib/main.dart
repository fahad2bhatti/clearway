import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_identity.dart';
import 'features/home/home_screen.dart';
import 'game/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const PhoolRastaApp());
}

class PhoolRastaApp extends StatefulWidget {
  const PhoolRastaApp({super.key});

  @override
  State<PhoolRastaApp> createState() => _PhoolRastaAppState();
}

class _PhoolRastaAppState extends State<PhoolRastaApp> {
  var _playing = false;
  var _level = 1;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppIdentity.name,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff182329),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xffffb347),
        secondary: Color(0xff4ecac1),
        surface: Color(0xff25343a),
        onPrimary: Color(0xff182329),
        onSurface: Color(0xfffff3d8),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xfffff3d8),
        displayColor: const Color(0xfffff3d8),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xff33434a),
        contentTextStyle: TextStyle(color: Color(0xfffff3d8)),
      ),
    ),
    home: _playing
        ? GameScreen(
            startingLevel: _level,
            onHome: (level) => setState(() {
              _level = level;
              _playing = false;
            }),
            onLevelChanged: (level) => setState(() => _level = level),
          )
        : HomeScreen(
            currentLevel: _level,
            onPlay: (level) => setState(() {
              _level = level;
              _playing = true;
            }),
          ),
  );
}
