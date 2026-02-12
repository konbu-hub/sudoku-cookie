import 'dart:math';
import 'package:flutter/foundation.dart'; // compute用

/// 数独エンジン - パズル生成と検証を担当
class SudokuEngine {
  final Random _random;

  SudokuEngine({int? seed}) : _random = Random(seed);

  /// 指定された位置に数字を配置できるかチェック
  bool isSafe(List<List<int>> grid, int row, int col, int num) {
    // 行のチェック
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == num) return false;
    }

    // 列のチェック
    for (int x = 0; x < 9; x++) {
      if (grid[x][col] == num) return false;
    }

    // 3x3ブロックのチェック
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }
// ... (中略) ...




  /// グリッドを完全に埋める(ランダムな完成済み数独を生成)
  bool fillGrid(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0) {
          List<int> nums = List.generate(9, (index) => index + 1);
          nums.shuffle(_random);

          for (int num in nums) {
            if (isSafe(grid, i, j, num)) {
              grid[i][j] = num;
              if (fillGrid(grid)) return true;
              grid[i][j] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// 解の個数をカウントする (2つ以上見つかったら打ち切り)
  int countSolutions(List<List<int>> grid, {int limit = 2}) {
    // コピーを作成して再帰処理（元のグリッドを破壊しないため）とは限らないが、
    // ここでは再帰的にバックトラッキングする際に空セルを探す
    
    // 空セルを探す
    int row = -1;
    int col = -1;
    bool isEmpty = true;
    
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0) {
          row = i;
          col = j;
          isEmpty = false;
          break;
        }
      }
      if (!isEmpty) break;
    }

    // すべて埋まっている場合、解が見つかった
    if (isEmpty) return 1;

    int count = 0;
    for (int num = 1; num <= 9; num++) {
      if (isSafe(grid, row, col, num)) {
        grid[row][col] = num;
        count += countSolutions(grid, limit: limit);
        grid[row][col] = 0; // バックトラック

        if (count >= limit) return count;
      }
    }
    return count;
  }
  
  /// 指定された難易度でパズルを生成
  /// 
  /// [difficulty] - 'easy', 'medium', 'hard', 'expert', 'extreme'
  /// 戻り値: [puzzle, solution] のリスト
  List<List<List<int>>> generatePuzzle(String difficulty) {
    // 目標とする空白の数 (現実的な難易度設定)
    // 最小ヒント数は17なので、空白最大は64 (81-17)
    // Extremeでもヒント25程度(空白56)が現実的な生成限界に近い
    Map<String, int> targetEmptyMap = {
      'easy': 32,    // Hint ~49
      'medium': 40,  // Hint ~41
      'hard': 46,    // Hint ~35
      'expert': 52,  // Hint ~29
      'extreme': 56, // Hint ~25
    };

    int targetEmpty = targetEmptyMap[difficulty] ?? 40;
    
    // 1. 完全に埋まった盤面を作成
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    fillGrid(grid);

    // 解答を保存 (ディープコピー)
    List<List<int>> solution = List.generate(
      9,
      (i) => List.from(grid[i]),
    );

    // 2. 穴をあける (一意性を保ちながら)
    List<List<int>> puzzle = List.generate(
      9,
      (i) => List.from(grid[i]),
    );
    
    // 全マスのインデックスリストを作成してシャッフル
    List<Point<int>> positions = [];
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        positions.add(Point(i, j));
      }
    }
    positions.shuffle(_random);
    
    int currentEmpty = 0;
    
    // ランダムな順序で穴あけを試行
    for (var pos in positions) {
      if (currentEmpty >= targetEmpty) break; // 目標達成

      int row = pos.x;
      int col = pos.y;
      int backup = puzzle[row][col];
      
      // 穴を空ける
      puzzle[row][col] = 0;
      
      // 解が一意かチェック
      // puzzleは書き換えられるのでコピーを渡す必要はない(再帰内で戻される)
      // ただしcountSolutionsはgridを書き換えるので、
      // puzzle自体を渡して良いが、countSolutions内で戻し忘れると壊れる
      // 今回の実装ではcountSolutionsはバックトラックして0に戻すので安全だが、
      // 念のためコピーを渡すのが安全
      List<List<int>> checkGrid = List.generate(9, (i) => List.from(puzzle[i]));
      
      int solutions = countSolutions(checkGrid);
      
      if (solutions != 1) {
        // 解が複数ある、または解なし(ありえないが) -> 元に戻す
        puzzle[row][col] = backup;
      } else {
        // 一意なら採用
        currentEmpty++;
      }
    }

    return [puzzle, solution];
  }

  /// 指定された位置に配置可能な候補数字のリストを取得
  List<int> getCandidates(List<List<int>> grid, int row, int col) {
    if (grid[row][col] != 0) return [];

    List<int> candidates = [];
    for (int num = 1; num <= 9; num++) {
      if (isSafe(grid, row, col, num)) {
        candidates.add(num);
      }
    }
    return candidates;
  }

  /// パズルが完成しているかチェック
  bool isComplete(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0) return false;
      }
    }
    return true;
  }
}

/// 別スレッドで実行するためのエントリーポイント関数
/// compute() から呼び出すため、トップレベル関数である必要がある
List<List<List<int>>> generatePuzzleWorker(Map<String, dynamic> params) {
  final difficulty = params['difficulty'] as String;
  final seed = params['seed'] as int?; // seedがあれば固定生成
  final engine = SudokuEngine(seed: seed);
  return engine.generatePuzzle(difficulty);
}
