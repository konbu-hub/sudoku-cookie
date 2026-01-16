import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';

/// 数独グリッドウィジェット
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        if (!gameProvider.hasActivePuzzle) {
          return const Center(
            child: Text('パズルを読み込み中...'),
          );
        }

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                childAspectRatio: 1,
              ),
              itemCount: 81,
              itemBuilder: (context, index) {
                int row = index ~/ 9;
                int col = index % 9;
                return _buildCell(context, gameProvider, row, col);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(BuildContext context, GameProvider gameProvider, int row, int col) {
    final puzzle = gameProvider.currentPuzzle!;
    final value = puzzle.puzzle[row][col];
    final isFixed = puzzle.isFixed(row, col);
    final isSelected = gameProvider.selectedRow == row && gameProvider.selectedCol == col;
    final theme = Theme.of(context);

    // ハイライト判定
    bool isHighlighted = false;
    if (gameProvider.selectedRow != null && gameProvider.selectedCol != null) {
      final selectedRow = gameProvider.selectedRow!;
      final selectedCol = gameProvider.selectedCol!;
      
      // 同じ行・列・ブロック
      if (row == selectedRow || col == selectedCol ||
          (row ~/ 3 == selectedRow ~/ 3 && col ~/ 3 == selectedCol ~/ 3)) {
        isHighlighted = true;
      }
    }

    // Lightning/FastPencilモードでの数字ハイライト
    bool isNumberHighlighted = false;
    if (gameProvider.gameState.selectedNumber != null &&
        (gameProvider.gameState.isLightningMode || gameProvider.gameState.isFastPencil)) {
      if (value == gameProvider.gameState.selectedNumber) {
        isNumberHighlighted = true;
      }
    }

    // エラーセル判定
    bool isErrorCell = false;
    if (gameProvider.gameState.errorCell != null) {
      final errorRow = gameProvider.gameState.errorCell!['row'];
      final errorCol = gameProvider.gameState.errorCell!['col'];
      if (row == errorRow && col == errorCol) {
        isErrorCell = true;
      }
    }

    Widget cellWidget = GestureDetector(
      onTap: () => gameProvider.selectCell(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isErrorCell
              ? Colors.red.withOpacity(0.3) // エラーセルは赤い背景
              : isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : isNumberHighlighted
                      ? Colors.blueAccent.withOpacity(0.25)
                      : isHighlighted
                          ? theme.colorScheme.primary.withOpacity(0.05)
                          : Colors.transparent,
          border: isErrorCell
              ? Border.all(color: Colors.red, width: 3) // エラーセルは赤い枠線
              : Border(
                  top: BorderSide(
                    color: row % 3 == 0
                        ? theme.dividerColor.withOpacity(0.8)
                        : theme.dividerColor.withOpacity(0.1),
                    width: row % 3 == 0 ? 2 : 0.5,
                  ),
                  left: BorderSide(
                    color: col % 3 == 0
                        ? theme.dividerColor.withOpacity(0.8)
                        : theme.dividerColor.withOpacity(0.1),
                    width: col % 3 == 0 ? 2 : 0.5,
                  ),
                  right: col == 8
                      ? BorderSide(
                          color: theme.dividerColor.withOpacity(0.8),
                          width: 2,
                        )
                      : BorderSide.none,
                  bottom: row == 8
                      ? BorderSide(
                          color: theme.dividerColor.withOpacity(0.8),
                          width: 2,
                        )
                      : BorderSide.none,
                ),
          boxShadow: isNumberHighlighted
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    spreadRadius: 0.5,
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Center(
          child: value != 0
              ? Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: isFixed ? FontWeight.bold : FontWeight.w600,
                    // ライトモード対応: 明るい背景でも見やすい色
                    color: isNumberHighlighted
                        ? Colors.cyanAccent
                        : isFixed
                            ? (theme.brightness == Brightness.light
                                ? Colors.black87
                                : theme.textTheme.bodyLarge?.color)
                            : (theme.brightness == Brightness.light
                                ? Colors.indigo.shade900
                                : theme.colorScheme.primary.withOpacity(0.9)),
                    shadows: isNumberHighlighted
                        ? [
                            Shadow(
                                blurRadius: 3,
                                color: Colors.blue.withOpacity(0.5),
                                offset: const Offset(0, 0))
                          ]
                        : null,
                  ),
                )
              : gameProvider.gameState.isFastPencil
                  ? _buildCandidates(context, gameProvider, row, col)
                  : null,
        ),
      ),
    );

    // エラーセルにシェイクアニメーションを追加
    if (isErrorCell) {
      return cellWidget.animate().shake(duration: 500.ms, hz: 4, rotation: 0.05);
    }
    return cellWidget;
  }

  /// 候補数字を表示(FastPencilモード)
  Widget _buildCandidates(BuildContext context, GameProvider gameProvider, int row, int col) {
    final candidates = gameProvider.getCandidates(row, col);
    final selectedNumber = gameProvider.gameState.selectedNumber;

    return GridView.builder(
      padding: const EdgeInsets.all(2), // 少し余白
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        int num = index + 1;
        bool isCandidate = candidates.contains(num);
        bool isHighlighted = selectedNumber == num;

        if (!isCandidate) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: isHighlighted 
                ? Colors.blueAccent.withOpacity(0.9) // ハイライト時は青背景
                : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              num.toString(),
              style: TextStyle(
                fontSize: 10,
                color: isHighlighted
                    ? Colors.white // ハイライト時は白抜き
                    : (Theme.of(context).brightness == Brightness.light
                        ? Colors.indigo.shade700 // ライトモード: 濃い青
                        : Colors.cyanAccent.withOpacity(0.6)), // ダークモード: シアン
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
