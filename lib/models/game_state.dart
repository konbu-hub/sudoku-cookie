/// ゲーム状態のデータモデル
class GameState {
  final int errors;
  final int time; // 秒単位
  final int hintsUsed;
  final bool isLightningMode;
  final bool isFastPencil;
  final int? selectedNumber; // Lightning/FastPencilモードで選択中の数字
  final String username;
  final int mascotClicks;
  final bool isHintDisabled;
  final Map<String, int>? errorCell; // エラーが発生したセル {"row": x, "col": y}
  final int pendingPoints; // クリア前の暫定ポイント
  final bool isScoreInvalid; // スコアが無効化されているか(マスコット10回クリック時)

  GameState({
    this.errors = 0,
    this.time = 0,
    this.hintsUsed = 0,
    this.isLightningMode = false,
    this.isFastPencil = false,
    this.selectedNumber,
    this.username = '',
    this.mascotClicks = 0,
    this.isHintDisabled = false,
    this.errorCell,
    this.pendingPoints = 0,
    this.isScoreInvalid = false,
  });

  GameState copyWith({
    int? errors,
    int? time,
    int? hintsUsed,
    bool? isLightningMode,
    bool? isFastPencil,
    int? selectedNumber,
    String? username,
    bool clearSelectedNumber = false,
    int? mascotClicks,
    bool? isHintDisabled,
    Map<String, int>? errorCell,
    bool clearErrorCell = false,
    int? pendingPoints,
    bool? isScoreInvalid,
  }) {
    return GameState(
      errors: errors ?? this.errors,
      time: time ?? this.time,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isLightningMode: isLightningMode ?? this.isLightningMode,
      isFastPencil: isFastPencil ?? this.isFastPencil,
      selectedNumber: clearSelectedNumber ? null : (selectedNumber ?? this.selectedNumber),
      username: username ?? this.username,
      mascotClicks: mascotClicks ?? this.mascotClicks,
      isHintDisabled: isHintDisabled ?? this.isHintDisabled,
      errorCell: clearErrorCell ? null : (errorCell ?? this.errorCell),
      pendingPoints: pendingPoints ?? this.pendingPoints,
      isScoreInvalid: isScoreInvalid ?? this.isScoreInvalid,
    );
  }

  /// タイマー表示用のフォーマット (MM:SS)
  String get formattedTime {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// エラー表示用のフォーマット (X/3)
  String get formattedErrors {
    return '$errors/3';
  }

  /// ヒント表示用のフォーマット (X/3)
  String get formattedHints {
    if (isHintDisabled) return 'ヒント (禁止中)';
    return 'ヒント ($hintsUsed/3)';
  }

  /// ゲームオーバーかどうか
  bool get isGameOver {
    return errors >= 3 || mascotClicks >= 10;
  }

  /// ヒントが使用可能かどうか
  bool get canUseHint {
    return !isHintDisabled && hintsUsed < 3;
  }

  /// ポイント表示用のフォーマット
  String get formattedPoints {
    return '$pendingPoints pt';
  }
}
