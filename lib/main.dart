import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/title_screen.dart';
import 'utils/theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'controllers/audio_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // オーディオ初期化
  await AudioController().init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const SudokuCookieApp());
}


class SudokuCookieApp extends StatefulWidget {
  const SudokuCookieApp({super.key});

  @override
  State<SudokuCookieApp> createState() => _SudokuCookieAppState();
}

class _SudokuCookieAppState extends State<SudokuCookieApp> {
  
  @override
  void initState() {
    super.initState();
    // splash logic handled in SplashScreen widget now
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'おしゃべりクッキーのSUDOKU',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            themeMode: themeProvider.themeMode,
            home: const InitialScreen(), // 3秒後にタイトル画面に遷移
          );
        },
      ),
    );
  }
}

/// 初期画面(ネイティブスプラッシュ表示後、タイトル画面に遷移)
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    // 3秒後にタイトル画面に遷移
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ネイティブスプラッシュと同じデザインを表示
    return Scaffold(
      backgroundColor: const Color(0xFF1a237e), // Dark indigo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // クッキー画像
            Image.asset(
              'assets/images/cookie_mascot_evil.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 100),
            // 企業ロゴ
            Image.asset(
              'assets/images/konbu_branding_padded.png',
              width: 250,
            ),
          ],
        ),
      ),
    );
  }
}
