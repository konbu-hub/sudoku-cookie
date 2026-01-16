import 'package:flutter/material.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // タップのみで遷移するため、自動遷移タイマーは削除
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Native Splashと同じ見た目を再現
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Dark Indigo (matched to native splash)
      body: GestureDetector(
        onTap: _navigateToMain, // タップでスキップ
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アプリアイコン
                  Image.asset(
                    'assets/images/cookie_mascot_evil.png',
                    width: 144,
                    height: 144,
                  ),
                  const SizedBox(height: 24),
                  // ブランディングロゴ
                  Image.asset(
                    'assets/images/konbu_branding_padded.png',
                    width: 200,
                  ),
                ],
              ),
            ),
            // "タップしてスタート"のメッセージを強調
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white70,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'タップしてスタート',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
