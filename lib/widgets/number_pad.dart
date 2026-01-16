import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../controllers/audio_controller.dart';


/// 数字パッドウィジェット
class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final remainingCounts = gameProvider.getRemainingCounts();
        final selectedNumber = gameProvider.gameState.selectedNumber;
        final isLightningMode = gameProvider.gameState.isLightningMode;

        return SizedBox(
          height: 72, // 高さを確保して押しやすく
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(9, (index) {
              int num = index + 1;
              int remaining = remainingCounts[num] ?? 0;
              bool isSelected = selectedNumber == num;
              bool isCompleted = remaining == 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2), // 間隔を少し詰める
                  child: _NumberButton(
                    number: num,
                    remaining: remaining,
                    isSelected: isSelected,
                    isCompleted: isCompleted,
                    isLightningMode: isLightningMode,
                    onPressed: () => _handleNumberPress(context, gameProvider, num),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _handleNumberPress(BuildContext context, GameProvider gameProvider, int num) {
    AudioController().playInput();
    if (gameProvider.gameState.isLightningMode || gameProvider.gameState.isFastPencil) {
      gameProvider.selectNumber(num);
    } else {
      if (gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
        gameProvider.handleInput(
          gameProvider.selectedRow!,
          gameProvider.selectedCol!,
          num,
        );
      }
    }
  }
}

/// Cyberpunk Styled Number Button
class _NumberButton extends StatelessWidget {
  final int number;
  final int remaining;
  final bool isSelected;
  final bool isCompleted;
  final bool isLightningMode;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.isSelected,
    required this.isCompleted,
    required this.isLightningMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // カラーパレット定義
    final baseColor = isCompleted 
        ? Colors.grey.withOpacity(0.3) 
        : (isSelected ? Colors.white : Colors.cyanAccent);
    
    final borderColor = isCompleted
        ? Colors.transparent
        : (isSelected ? Colors.cyanAccent : Colors.cyan.withOpacity(0.3));

    final backgroundColor = isSelected
        ? Colors.cyan.withOpacity(0.4)
        : (isCompleted ? Colors.black12 : Colors.black45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCompleted ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // メイン数字
              Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: baseColor,
                  height: 1.0,
                  shadows: isSelected || (!isCompleted)
                      ? [
                          Shadow(
                            color: isSelected ? Colors.cyan : Colors.black,
                            blurRadius: isSelected ? 10 : 2,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              // 残数表示 (またはチェックマーク)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.greenAccent)
                    : Text(
                        '$remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.cyanAccent : Colors.white54,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
