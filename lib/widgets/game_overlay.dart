import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';

class GameOverlay extends StatefulWidget {
  const GameOverlay({super.key});

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (gameProvider.isGameClear) {
          _confettiController.play();
          
          // デイリーミッションかどうかで表示を切り替え
          final isDaily = gameProvider.isDailyMission;
          final title = isDaily ? 'MISSION CLEAR!' : 'クリア！';
          final message = isDaily 
              ? (gameProvider.isDailyBonusApplied
                  ? 'おめでとう！\n本日のミッション達成だ！\nポイント10倍！！'
                  : 'ミッションクリア！\n遅刻だなぁ...今回は通常ポイントだ。\n次は当日に来な！')
              : 'おめでとうございます！\nクッキーが悔しがっています！';
          
          return Stack(
            children: [
              _buildOverlay(
                context,
                title: title,
                message: message,
                color: Colors.green,
                icon: Icons.emoji_events,
                onRestart: () {
                   Navigator.of(context).pop(true); // trueを返してリロード等をトリガー可能に
                },
                gameProvider: gameProvider,
                isDaily: isDaily,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                ),
              ),
            ],
          );
        } else if (gameProvider.gameState.isGameOver) {
          return _buildOverlay(
            context,
            title: 'ゲームオーバー',
            message: 'ドンマイ！\n次はきっとできるよ！',
            color: Colors.red,
            icon: Icons.mood_bad,
            onRestart: () {
               Navigator.of(context).pop(); // タイトルに戻る
            },
             gameProvider: gameProvider,
          );
        } else if (gameProvider.isRunningAway) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(), // タップで戻る
            child: Container(
              color: Colors.black.withOpacity(0.85),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/cookie_mascot_evil.png',
                      width: 250,
                      height: 250,
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(duration: 500.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                     .shake(hz: 2, curve: Curves.easeInOut),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]?.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: Text(
                        gameProvider.tauntMessage ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'タップしてタイトルへ戻る',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .fadeIn(duration: const Duration(seconds: 1))
                     .fadeOut(delay: const Duration(seconds: 1), duration: const Duration(seconds: 1)),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOverlay(
    BuildContext context, {
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    required VoidCallback onRestart,
    required GameProvider gameProvider,
    bool isDaily = false,
  }) {
    // 確定スコアがあればそれを使用、なければ暫定スコア
    final score = gameProvider.lastTotalScore ?? gameProvider.gameState.pendingPoints;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isDaily ? FontWeight.bold : FontWeight.normal,
                  color: isDaily ? Colors.orange : null,
                ),
              ),
              const SizedBox(height: 16),
              // 獲得ポイント表示
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '獲得ポイント: $score pt',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'タイム: ${gameProvider.gameState.formattedTime}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(isDaily ? 'カレンダーへ戻る' : 'タイトルへ戻る'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
