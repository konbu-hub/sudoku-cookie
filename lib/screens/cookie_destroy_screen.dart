import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cookie_destroy_game_provider.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

class CookieDestroyScreen extends StatefulWidget {
  const CookieDestroyScreen({super.key});

  @override
  State<CookieDestroyScreen> createState() => _CookieDestroyScreenState();
}

class _CookieDestroyScreenState extends State<CookieDestroyScreen> {
  ui.Image? _cookieImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final image = await _loadAssetImage('assets/images/cookie_mascot_evil.png');
    setState(() {
      _cookieImage = image;
    });
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CookieDestroyGameProvider()..startGame(),
      child: Scaffold(
        body: SafeArea(
          child: Consumer<CookieDestroyGameProvider>(
            builder: (context, provider, child) {
              if (provider.isGameClear) {
                return _buildClearScreen(context, provider);
              }
              
              return Stack(
                children: [
                  // ボス感ある背景
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.red.shade900,
                          Colors.black,
                          Colors.black,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  
                  // ゲームエリア
                  GestureDetector(
                    onPanUpdate: (details) {
                      provider.handleSwipe(details.localPosition);
                    },
                    onPanEnd: (_) {
                      provider.clearSwipe();
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: CookieDestroyPainter(
                          cookies: provider.cookies,
                          swipePoints: provider.swipePoints,
                          slicedCookies: provider.slicedCookies,
                          cookieImage: _cookieImage,
                        ),
                      ),
                    ),
                  ),
                  
                  // UI オーバーレイ
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // スコア表示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: Text(
                            'スコア: ${provider.score}/100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // タイマー表示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: Text(
                            provider.formattedTime,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // DANGERアラート(ボス登場時)
                  if (provider.showDangerAlert)
                    Positioned.fill(
                      child: Container(
                        color: Colors.red.withOpacity(0.3),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'DANGER!!!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.red,
                                      blurRadius: 30,
                                    ),
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                               .shake(duration: 200.ms, hz: 10)
                               .fadeIn(duration: 100.ms)
                               .then()
                               .fadeOut(duration: 100.ms),
                              const SizedBox(height: 20),
                              Text(
                                'BOSS APPROACHING!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.red,
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                               .fadeIn(duration: 300.ms)
                               .then()
                               .fadeOut(duration: 300.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClearScreen(BuildContext context, CookieDestroyGameProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.amber.shade700, Colors.black],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'まだまだ世の中にクッキーはある!\n引き続き殲滅しよう!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'クリアタイム: ${provider.formattedTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  'タイトルへ戻る',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// カスタムペインター
class CookieDestroyPainter extends CustomPainter {
  final List<FlyingCookie> cookies;
  final List<Offset> swipePoints;
  final List<SlicedCookie> slicedCookies;
  final ui.Image? cookieImage;

  CookieDestroyPainter({
    required this.cookies,
    required this.swipePoints,
    required this.slicedCookies,
    this.cookieImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // スワイプ軌跡を描画(赤い軌跡)
    if (swipePoints.length > 1) {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < swipePoints.length - 1; i++) {
        canvas.drawLine(swipePoints[i], swipePoints[i + 1], paint);
      }
    }

    // 破裂エフェクト(切られたクッキー)
    for (final sliced in slicedCookies) {
      final opacity = (1.0 - sliced.animationProgress).clamp(0.0, 1.0);
      
      // パーティクル効果
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + sliced.animationProgress * math.pi;
        final distance = sliced.animationProgress * 50;
        final particlePos = sliced.position + Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance,
        );
        
        final particlePaint = Paint()
          ..color = Colors.brown.withOpacity(opacity * 0.8);
        canvas.drawCircle(particlePos, 5, particlePaint);
      }
    }

    // クッキーを描画(画像使用)
    if (cookieImage != null) {
      for (final cookie in cookies) {
        if (cookie.isSliced) continue;

        final radius = cookie.isBoss ? 50.0 : 30.0;
        final imageSize = radius * 2;

        canvas.save();
        canvas.translate(cookie.position.dx, cookie.position.dy);
        canvas.rotate(cookie.rotation);

        // 画像を描画
        final srcRect = Rect.fromLTWH(
          0,
          0,
          cookieImage!.width.toDouble(),
          cookieImage!.height.toDouble(),
        );
        final dstRect = Rect.fromCenter(
          center: Offset.zero,
          width: imageSize,
          height: imageSize,
        );

        final paint = Paint()
          ..filterQuality = FilterQuality.high;

        // ボスの場合は赤いオーバーレイ
        if (cookie.isBoss) {
          canvas.drawImageRect(cookieImage!, srcRect, dstRect, paint);
          final overlayPaint = Paint()
            ..color = Colors.red.withOpacity(0.3)
            ..blendMode = BlendMode.srcOver;
          canvas.drawRect(dstRect, overlayPaint);
        } else {
          canvas.drawImageRect(cookieImage!, srcRect, dstRect, paint);
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CookieDestroyPainter oldDelegate) => true;
}

// クッキークラス
class FlyingCookie {
  Offset position;
  Offset velocity;
  bool isSliced;
  bool isBoss;
  double rotation;

  FlyingCookie({
    required this.position,
    required this.velocity,
    this.isSliced = false,
    this.isBoss = false,
    this.rotation = 0,
  });
}

// 切られたクッキーのエフェクト用
class SlicedCookie {
  final Offset position;
  final double animationProgress;

  SlicedCookie({
    required this.position,
    required this.animationProgress,
  });
}
