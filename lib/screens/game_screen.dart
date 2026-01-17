import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/sudoku_grid.dart';
import '../widgets/number_pad.dart';
import '../widgets/game_overlay.dart';
import '../widgets/cookie_mascot.dart';
import '../controllers/audio_controller.dart';
import '../repositories/ranking_repository.dart';
import '../data/mascot_messages.dart';




/// ゲーム画面
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  @override
  late AnimationController _explosionController;
  bool _hasExploded = false;
  bool _showFlash = false; // フラッシュエフェクト用

  @override
  void initState() {
    super.initState();
    // BGMをメインゲーム用に切り替え
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController().playBgm(fileName: 'main_bgm.mp3');
      
      // 完成イベントリスナー登録
      final gp = context.read<GameProvider>();
      gp.numberCompletionEvent.addListener(_onNumberComplete);
    });
    
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    

  }

  void _onNumberComplete() {
    final gp = context.read<GameProvider>();
    if (gp.numberCompletionEvent.value != null) {
      // 波動エフェクト開始
      _explosionController.forward(from: 0);
      
      // 画面全体をフラッシュさせる(クールな白/青系で控えめに)
      setState(() {
        _showFlash = true;
      });
      
      // フラッシュを0.2秒後に消す
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showFlash = false;
          });
        }
      });
    }
  }

  @override
  @override
  void dispose() {
    // リスナー解除は安全のためtry-catch、または参照保持が必要だが
    // 今回は画面破棄=Providerも破棄に近いので簡略化
    // ただしBest Practiceとしてremove推奨
    // final gp = context.read<GameProvider>(); // may throw if unmounted
    // gp.numberCompletionEvent.removeListener(_onNumberComplete);
    
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        // Androidの戻るボタンを押したときの処理
        AudioController().playSelect();
        _showQuitConfirmation(context);
        return false; // 戻るボタンの既定の動作をキャンセル
      },
      child: Scaffold(
        appBar: AppBar(
        leadingWidth: 120,
        leading: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return TextButton(
              onPressed: () {
                AudioController().playSelect();
                // 直接確認ダイアログを表示(事前の煽りは削除)
                _showQuitConfirmation(context);
              },
              child: const Text(
                'ビビってやめる',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            );
          },
        ),
        title: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final difficulty = gameProvider.currentPuzzle?.difficulty;
            return Text(
              difficulty != null 
                  ? difficulty.displayName
                  : 'ゲーム',
              overflow: TextOverflow.visible,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            );
          },
        ),
        actions: [
          // タイマー
          Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    gameProvider.gameState.formattedTime,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          // ゲーム設定メニュー
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AudioController().playSelect();
              _showGameSettingsMenu(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 上部にスペースを追加
                const SizedBox(height: 24),
                
                // 数独グリッドとポイント表示
                Expanded(
                  child: Stack(
                    children: [
                      // 数独グリッド
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: SudokuGrid(),
                        ),
                      ),
                      // ポイント表示（右上）
                      Positioned(
                        top: 60,
                        right: 8,
                        child: Consumer<GameProvider>(
                          builder: (context, gameProvider, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade700,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    gameProvider.gameState.formattedPoints,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 数字パッド
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: NumberPad(),
                ),
                
                // コントロールボタン
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Consumer<GameProvider>(
                          builder: (context, gameProvider, child) {
                            // 爆発トリガーチェック
                            if (gameProvider.gameState.mascotClicks == 0) {
                              _hasExploded = false; // ゲームリセット時はフラグもリセット
                            }
                            if (gameProvider.gameState.mascotClicks >= 5 && !_hasExploded) {
                              _hasExploded = true;
                              _explosionController.forward(from: 0);
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: gameProvider.gameState.canUseHint
                                      ? () {
                                          AudioController().playSelect();
                                          gameProvider.useHint();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lightbulb, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ヒント',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${3 - gameProvider.gameState.hintsUsed}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<GameProvider>(
                          builder: (context, gameProvider, child) {
                            final isActive = gameProvider.gameState.isFastPencil;
                            return ElevatedButton.icon(
                              onPressed: () {
                                AudioController().playSelect();
                                gameProvider.toggleFastPencilMode();
                              },
                              icon: Icon(
                                isActive ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 20,
                              ),
                              label: const Text(
                                'オートメモ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                foregroundColor: isActive
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                elevation: isActive ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<GameProvider>(
                          builder: (context, gameProvider, child) {
                            final isActive = gameProvider.gameState.isLightningMode;
                            return ElevatedButton.icon(
                              onPressed: () {
                                AudioController().playSelect();
                                gameProvider.toggleLightningMode();
                              },
                              icon: Icon(
                                isActive ? Icons.flash_on : Icons.flash_off,
                                size: 20,
                              ),
                              label: const Text(
                                'クイック',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                foregroundColor: isActive
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                elevation: isActive ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const CookieMascot(),
          // 右上の「愚か」カウンター
          Positioned(
            top: 20,
            right: 20,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '愚か: ${gameProvider.gameState.formattedErrors}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
          const GameOverlay(),
          
          // 画面フラッシュエフェクト
          if (_showFlash)
            AnimatedOpacity(
              opacity: _showFlash ? 0.3 : 0.0, // 透明度を下げて控えめに
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.cyanAccent.withOpacity(0.3), // 黄色からクールなシアンへ
              ),
            ),
          
          // 波動エフェクト (Ripple)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _explosionController,
              builder: (context, child) {
                if (_explosionController.value == 0 || _explosionController.isDismissed) {
                   return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: RipplePainter(
                    progress: _explosionController.value,
                    color: Colors.cyanAccent,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  /// 星型のパスを描画
  Path drawStar(Size size) {
    // 単純な星型
    double cx = size.width / 2;
    double cy = size.height / 2;
    double outerRadius = size.width / 2;
    double innerRadius = outerRadius / 2.5;
    
    Path path = Path();
    // 5芒星の描画ロジック省略（単純な菱形でも代用可、あるいは円）
    // ここでは円にする (簡単のため)
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius));
    return path;
    // 星型実装が長くなるので一旦円で実装
  }

  void _showGameSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final audio = AudioController();
          return Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        const Text(
                          'ゲーム設定',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // --- サウンド設定 ---
                    const Text('サウンド', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                     SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('すべてミュート'),
                      value: audio.isMuted,
                      onChanged: (val) {
                        setSheetState(() {
                          audio.toggleMute().then((_) => setSheetState(() {}));
                        });
                      },
                      secondary: Icon(
                        audio.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: audio.isMuted ? Colors.red : null,
                      ),
                    ),
                    // SFX Slider
                    Row(
                      children: [
                        const Text('SE', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Slider(
                            value: audio.sfxVolume,
                            min: 0.0, max: 1.0,
                            onChanged: (val) {
                              setSheetState(() {
                                audio.setSfxVolume(val);
                                if (val > 0) audio.playInput(); // Preview
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    // BGM Slider
                    Row(
                      children: [
                        const Text('BGM', style: TextStyle(fontSize: 14)),
                         Expanded(
                          child: Slider(
                            value: audio.bgmVolume,
                            min: 0.0, max: 1.0,
                            onChanged: (val) {
                              setSheetState(() {
                                audio.setBgmVolume(val);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- ゲームプレイ設定 ---
                    const Text('ゲームプレイ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // オートメモ
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('オートメモ'),
                  subtitle: const Text('自動でメモを記入'),
                  value: gameProvider.gameState.isFastPencil,
                  onChanged: (value) {
                    gameProvider.toggleFastPencilMode();
                  },
                  secondary: Icon(
                    gameProvider.gameState.isFastPencil
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                ),
                
                // クイックモード
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('クイックモード'),
                  subtitle: const Text('連続入力モード'),
                  value: gameProvider.gameState.isLightningMode,
                  onChanged: (value) {
                    gameProvider.toggleLightningMode();
                  },
                  secondary: Icon(
                    gameProvider.gameState.isLightningMode
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ); 
      },
    );
    },
  ),
);
  }

  void _showQuitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本当に逃げるの？'),
        content: const Text('クッキー以下の小さいプライドさえも捨てることになりますが、よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('やっぱり続ける'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialogを閉じる
              AudioController().playReturn();
              RankingRepository().incrementRunAwayCount(); // 逃走回数を記録
              
              // 逃走演出を起動
              Provider.of<GameProvider>(context, listen: false).triggerRunAway();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('逃げる'),
          ),
        ],
      ),
    );
  }
}

class ExplosionWidget extends StatelessWidget {
  final AnimationController controller;

  const ExplosionWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final val = controller.value;
        // 0.0 -> 1.0
        // Rapid expansion: 0 -> 1.5 scale
        // Opacity: 1.0 -> 0.0 at end
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Core Flash
            Opacity(
              opacity: (1 - val).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 + val * 3, // Explode cleanly
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red.withOpacity(0),
                      ],
                      stops: const [0.1, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Outer Ring
             Opacity(
              opacity: (1 - val).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 2 + val * 4, 
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withOpacity((1 - val).clamp(0,1)),
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
            // "Boom" Text (optional, but requested huge effect)
            if (val < 0.5)
              Opacity(
                 opacity: 1.0,
                 child: Transform.scale(
                   scale: 1 + val,
                   child: const Icon(Icons.cancel, color: Colors.red, size: 40),
                 ),
              ),
          ],
        );
      },
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 画面全体を覆うくらいの最大半径
    final maxRadius = size.shortestSide * 1.5;
    
    // 1つ目のリング
    final currentRadius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.8) // 少し透明度を下げる
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 * (1.0 - progress) // 外側にいくほど細く
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // ぼかし効果

    canvas.drawCircle(center, currentRadius, paint);
    
    // 2つ目のリング（遅れて広がる）
    if (progress > 0.2) {
       final progress2 = (progress - 0.2) / 0.8;
       final radius2 = maxRadius * progress2;
       final opacity2 = (1.0 - progress2).clamp(0.0, 1.0);
       
       final paint2 = Paint()
          ..color = color.withOpacity(opacity2 * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * (1.0 - progress2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
          
       canvas.drawCircle(center, radius2, paint2);
    }
    
    // 3つ目のリング（さらに遅れて広がる、細い）
    if (progress > 0.4) {
       final progress3 = (progress - 0.4) / 0.6;
       final radius3 = maxRadius * progress3;
       final opacity3 = (1.0 - progress3).clamp(0.0, 1.0);
       
       final paint3 = Paint()
          ..color = Colors.white.withOpacity(opacity3 * 0.6) // 白いアクセント
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1.0 - progress3);
          
       canvas.drawCircle(center, radius3, paint3);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
