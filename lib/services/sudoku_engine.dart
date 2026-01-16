import 'dart:math';

/// 数独エンジン - パズル生成と検証を担当
/// Python版(sudoku_engine.py)からの移植
class SudokuEngine {
  List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
  final Random _random = Random();

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

  /// 空のセルを見つける
  List<int>? findEmptyLocation(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0) return [i, j];
      }
    }
    return null;
  }

  /// バックトラッキングで数独を解く
  bool solve(List<List<int>> grid) {
    var empty = findEmptyLocation(grid);
    if (empty == null) return true;

    int row = empty[0];
    int col = empty[1];

    for (int num = 1; num <= 9; num++) {
      if (isSafe(grid, row, col, num)) {
        grid[row][col] = num;
        if (solve(grid)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

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

  /// 指定された難易度でパズルを生成
  /// 
  /// [difficulty] - 'easy', 'medium', 'hard', 'expert', 'extreme'
  /// 戻り値: [puzzle, solution] のリスト
  List<List<List<int>>> generatePuzzle(String difficulty) {
    // 難易度に応じた空白の数
    Map<String, List<int>> difficultyMap = {
      'easy': [30, 35],
      'medium': [40, 45],
      'hard': [50, 55],
      'expert': [60, 65],
      'extreme': [66, 70],
    };

    List<int> range = difficultyMap[difficulty] ?? [40, 45];
    int attempts = range[0] + _random.nextInt(range[1] - range[0] + 1);

    // 1. 完全に埋まった盤面を作成
    grid = List.generate(9, (_) => List.filled(9, 0));
    fillGrid(grid);

    // 解答を保存
    List<List<int>> solution = List.generate(
      9,
      (i) => List.from(grid[i]),
    );

    // 2. 穴をあける
    List<List<int>> puzzle = List.generate(
      9,
      (i) => List.from(grid[i]),
    );

    while (attempts > 0) {
      int row = _random.nextInt(9);
      int col = _random.nextInt(9);

      while (puzzle[row][col] == 0) {
        row = _random.nextInt(9);
        col = _random.nextInt(9);
      }

      puzzle[row][col] = 0;
      attempts--;
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

  /// 指定された入力が正しいかチェック
  bool isValidInput(List<List<int>> grid, int row, int col, int num) {
    // 一時的に配置してチェック
    int backup = grid[row][col];
    grid[row][col] = num;
    bool valid = isSafe(grid, row, col, num);
    grid[row][col] = backup;
    return valid;
  }
}
