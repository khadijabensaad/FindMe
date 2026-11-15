<<<<<<< HEAD
import 'package:find_me/splash_screen.dart';
import 'package:find_me/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
=======
import 'package:find_me/Auth/login.dart';
import 'package:find_me/main_screen.dart';
import 'package:find_me/splash_screen.dart';
import 'package:find_me/starting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
<<<<<<< HEAD
  await ThemeController.load();
=======
>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, mode, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FINDME',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        // Splash → (onboarding | login | app shell) depending on the stored token
        home: const SplashScreen(),
      ),
    );
  }
}
=======
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Find Me',
      theme: ThemeData(
       
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreenPage(),
    );
  }
}

>>>>>>> 3964aae69b872a8001568f41d0fea4c7d9427267
