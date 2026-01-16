/// 難易度レベル
enum Difficulty {
  easy('やわクッキー', 'easy'),
  medium('普通クッキー', 'medium'),
  hard('堅クッキー', 'hard'),
  expert('バリ堅クッキー', 'expert'),
  extreme('石', 'extreme');


  final String displayName;
  final String value;

  const Difficulty(this.displayName, this.value);

  static Difficulty fromValue(String value) {
    return Difficulty.values.firstWhere(
      (d) => d.value == value,
      orElse: () => Difficulty.medium,
    );
  }
}

/// 数独パズルのデータモデル
class SudokuPuzzle {
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final List<List<int>> initialPuzzle; // 初期状態(固定セル判定用)
  final Difficulty difficulty;

  SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
  }) : initialPuzzle = List.generate(
          9,
          (i) => List.from(puzzle[i]),
        );

  /// セルが初期状態(固定)かどうか
  bool isFixed(int row, int col) {
    return initialPuzzle[row][col] != 0;
  }

  /// 現在のパズルのコピーを取得
  List<List<int>> getPuzzleCopy() {
    return List.generate(9, (i) => List.from(puzzle[i]));
  }
}
