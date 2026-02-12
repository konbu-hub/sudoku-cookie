import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sudoku_puzzle.dart';
import '../models/game_state.dart';

import '../services/sudoku_engine.dart';
import '../services/auth_service.dart';
import '../controllers/audio_controller.dart';

import '../models/score_model.dart';
import '../repositories/ranking_repository.dart';
import 'package:uuid/uuid.dart';

// Play Games Services
import '../services/play_games_service.dart';
import '../utils/play_games_constants.dart';




/// ゲーム全体の状態を管理するProvider
class GameProvider extends ChangeNotifier {
  SudokuPuzzle? _currentPuzzle;
  GameState _gameState = GameState();
  final SudokuEngine _engine = SudokuEngine();
  Timer? _timer;
  bool _isGameClear = false;
  bool _isRunningAway = false;
  String? _tauntMessage;
  bool _isGenerating = false; // 生成中フラグ
  bool _isDailyMission = false; // デイリーミッションフラグ
  DateTime? _dailyDate; // デイリーミッションの日付
  int? _lastTotalScore; // 最後に保存した合計スコア（クリア画面用）
  bool _isDailyBonusApplied = false; // デイリーボーナス(10倍)が適用されたか


  // イベント通知用 (数字完成時にその数字をセット)
  final ValueNotifier<int?> numberCompletionEvent = ValueNotifier(null);


// ... (中略) ...

  /// デイリーミッション開始
  Future<void> startDailyMission(DateTime date) async {
    // 生成開始フラグON
    _isGenerating = true;
    _isDailyMission = true;
    _dailyDate = date;
    notifyListeners();

    // 既存のタイマーを停止
    _stopTimer();

    // 設定をロード
    final prefs = await SharedPreferences.getInstance();
    final isLightningMode = prefs.getBool('isLightningMode') ?? false;
    final isFastPencil = prefs.getBool('isFastPencil') ?? false;

    // シード生成 (YYYYMMDD)
    int seed = date.year * 10000 + date.month * 100 + date.day;
    
    // 難易度を日付でランダム決定 (Seedを使うので日替わり固定)
    final random = Random(seed);
    // Hard(50%), Expert(50%)
    final dailyDifficulty = random.nextBool() ? Difficulty.hard : Difficulty.expert;

    // パズルを生成
    try {
      var result = await compute(generatePuzzleWorker, {
        'difficulty': dailyDifficulty.value,
        'seed': seed,
      });
      _currentPuzzle = SudokuPuzzle(
        puzzle: result[0],
        solution: result[1],
        difficulty: dailyDifficulty,
      );
    } catch (e) {
      print("Daily Puzzle Generation Failed: $e");
      _isGenerating = false;
      notifyListeners();
      return;
    }

    // ゲーム状態をリセット
    final currentUsername = _gameState.username;
    _gameState = GameState(
      username: currentUsername,
      isLightningMode: isLightningMode,
      isFastPencil: isFastPencil,
    );
    
    _isGameClear = false;
    _isRunningAway = false;
    _tauntMessage = null;
    _selectedRow = null;
    _selectedCol = null;

    // 生成完了
    _isGenerating = false;

    // タイマー開始
    _startTimer();

    notifyListeners();
  }

  GameProvider() {
    _loadUsername();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // 1. 未ログインなら匿名サインイン
    if (AuthService().currentUser == null) {
      print("No user signed in. Attempting anonymous sign-in...");
      await AuthService().signInAnonymously();
    }

    // 2. データ移行チェック (Local -> Auth)
    await _checkAndMigrateData();

    // 3. 認証状態の監視
    AuthService().user.listen((user) async {
      if (user != null) {
        // 優先度ルール:
        // 1. 手動で設定した名前がある場合 (Prefs: is_manual_username == true) -> それを維持
        // 2. Googleアカウントの名前がある場合 -> それを反映 (初回ログイン時など)
        // 3. それ以外 -> デフォルト or 手動設定待ち
        
        final prefs = await SharedPreferences.getInstance();
        final isManual = prefs.getBool('is_manual_username') ?? false;

        // 手動設定されていない、かつGoogleアカウントに名前がある場合のみ上書き
        if (!isManual && user.displayName != null && user.displayName!.isNotEmpty) {
           _gameState = _gameState.copyWith(username: user.displayName!);
           // Prefsも更新しておくが、is_manualフラグは立てない（Google由来だから）
           await prefs.setString('username', user.displayName!);
        }
      }
      notifyListeners();
    });
  }

  Future<void> _checkAndMigrateData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final localId = prefs.getString('local_user_id');
    // このユーザーに対して移行済みかチェック
    final isMigrated = prefs.getBool('migrated_to_auth_${user.uid}') ?? false;

    if (localId != null && !isMigrated) {
      print("Migrating data from Local($localId) to Auth(${user.uid})...");
      await RankingRepository().migrateLocalData(localId, user.uid);
      await prefs.setBool('migrated_to_auth_${user.uid}', true);
      
      // ついでに名前もリモートに反映させておく
      await RankingRepository().updateRemoteUsername(_gameState.username);
    }
  }


  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    String savedName = prefs.getString('username') ?? '';
    
    if (savedName.isEmpty) {
      // 初回起動時: ランダムな名前を生成して保存
      final randomNum = Random().nextInt(9000) + 1000; // 1000-9999
      savedName = 'Player$randomNum';
      await prefs.setString('username', savedName);
    }
    
    // 設定の読み込み
    final isFastPencil = prefs.getBool('isFastPencil') ?? false;
    final isLightningMode = prefs.getBool('isLightningMode') ?? false;

    _gameState = _gameState.copyWith(
      username: savedName,
      isFastPencil: isFastPencil,
      isLightningMode: isLightningMode,
    );
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    // 手動更新されたことを記録
    await prefs.setBool('is_manual_username', true);
    
    _gameState = _gameState.copyWith(username: newName);
    notifyListeners();

    // Firestore上のユーザー名も更新
    await RankingRepository().updateRemoteUsername(newName);
  }


  // 選択中のセル
  int? _selectedRow;
  int? _selectedCol;

  // Getters
  SudokuPuzzle? get currentPuzzle => _currentPuzzle;
  GameState get gameState => _gameState;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get hasActivePuzzle => _currentPuzzle != null;

  bool get isGameClear => _isGameClear;
  bool get isRunningAway => _isRunningAway;
  bool get isGenerating => _isGenerating;
  bool get isDailyMission => _isDailyMission;
  String? get tauntMessage => _tauntMessage;
  int? get lastTotalScore => _lastTotalScore;
  bool get isDailyBonusApplied => _isDailyBonusApplied;

  /// 残りマス数
  int get remainingCells {
    if (_currentPuzzle == null) return 81;
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_currentPuzzle!.puzzle[i][j] == 0) {
          count++;
        }
      }
    }
    return count;
  }

  /// 進捗率 (0-100)
  int get progressPercentage {
    if (_currentPuzzle == null) return 0;
    int total = 81;
    int remaining = remainingCells;
    return ((total - remaining) / total * 100).floor();
  }


  /// 新しいゲームを開始
  Future<void> startNewGame(Difficulty difficulty, String username) async {
    // 通常モードなのでフラグOFF
    _isDailyMission = false;
    _dailyDate = null;

    // 生成開始フラグON
    _isGenerating = true;
    notifyListeners();

    // 既存のタイマーを停止
    _stopTimer();

    // 設定をロード
    final prefs = await SharedPreferences.getInstance();
    final isLightningMode = prefs.getBool('isLightningMode') ?? false;
    final isFastPencil = prefs.getBool('isFastPencil') ?? false;

    // パズルを生成 (別スレッドで実行)
    // 難易度が高いと時間がかかるため compute を使用
    try {
      var result = await compute(generatePuzzleWorker, {'difficulty': difficulty.value});
      _currentPuzzle = SudokuPuzzle(
        puzzle: result[0],
        solution: result[1],
        difficulty: difficulty,
      );
    } catch (e) {
      print("Puzzle Generation Failed: $e");
      // 生成失敗時のフォールバック処理が必要ならここに追加
      _isGenerating = false;
      notifyListeners();
      return;
    }

    // ゲーム状態をリセット
    // ユーザー名は現在の状態を引き継ぐ
    // 設定値も適用する
    final currentUsername = _gameState.username;
    _gameState = GameState(
      username: currentUsername,
      isLightningMode: isLightningMode,
      isFastPencil: isFastPencil,
    );
    
    _isGameClear = false;
    _isRunningAway = false;
    _tauntMessage = null;
    _selectedRow = null;
    _selectedCol = null;

    // 生成完了
    _isGenerating = false;

    // タイマー開始
    _startTimer();

    notifyListeners();
  }

  /// タイマーを開始
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _gameState = _gameState.copyWith(time: _gameState.time + 1);
      notifyListeners();
    });
  }

  /// タイマーを停止
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// セルを選択
  void selectCell(int row, int col) {
    if (_currentPuzzle == null) return;

    // Lightningモードの場合、選択中の数字があれば入力
    if (_gameState.isLightningMode && _gameState.selectedNumber != null) {
      handleInput(row, col, _gameState.selectedNumber!);
      return;
    }

    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  /// マスコットをタップ（煽られた罰）
  void handleMascotTap() {
    if (_gameState.isGameOver) return;
    
    _gameState = _gameState.copyWith(mascotClicks: _gameState.mascotClicks + 1);
    
    if (_gameState.mascotClicks == 5) {
      // 5回クリック: ヒント無効化 + 愚かポイント2(即死モード) + スコア無効化
      _gameState = _gameState.copyWith(
        isHintDisabled: true,
        errors: 2,
        isScoreInvalid: true,
      );
      AudioController().playError();
    }
    
    if (_gameState.mascotClicks >= 10) {
      // 10回クリック: 強制ゲームオーバー
      _gameState = _gameState.copyWith(
        errors: 3,
      );
      _stopTimer();
      AudioController().playGameOver();
      AudioController().vibrateMascotExplosion(); // 大きな振動
    }
    
    notifyListeners();
  }

  /// 煽り演出をトリガー
  void triggerTaunt(String message) {
    _tauntMessage = message;
    notifyListeners();
    // 一定時間後にリセット
    Timer(const Duration(seconds: 4), () { // 少し長めに
      _tauntMessage = null;
      notifyListeners();
    });
  }

  /// 逃げるボタン用のランダム煽り
  void triggerRunAwayTaunt() {
    // ランダムに1つ選択
    final message = (_runawayMessages..shuffle()).first;
    triggerTaunt(message);
  }

  static const List<String> _runawayMessages = [
    "お？逃げるのか？\nビビってんじゃねーよw",
    "クッキー以下のプライドも\n残ってないのかよw",
    "逃げ足だけは速いなw\n流石だわ",
    "敗北宣言あざーっすw\nもう二度と来るなよ",
    "腰抜け野郎がw\n一生数独に怯えてろw",
    "逃げるが勝ち？\nお前のはただの逃走だろw",
    "雑魚すぎて話にならんw",
    "お疲れ様でした〜w\n（二度と会いたくないけど）",
    "おいおい、冗談だろ？\nここで逃げるのかよw",
    "尻尾巻いて逃げる犬みたいだなw",
    "画面の前で泣いてんの？\n慰めてやろうか？w",
    "才能ないから辞めた方がいいよw\n正解！w",
    "お前には早すぎたんだよ\n出直してこい",
    "そんな根性で社会やっていけんの？\n心配だわ〜w",
    "時間の無駄だったな\n俺にとっても、お前にとってもw",
    "あ〜あ、つまんねー奴。\n消えろ消えろw",
    "数独如きに負けるとか\n人生ハードモードすぎんだろw",
    "逃げるボタン押す指だけは\n立派に動くなw",
    "さっさとアプリ消せよ\n容量の無駄だわw",
    "お前が諦めた瞬間、\n俺の勝利が確定したw",
    "悔しいか？ん？\n何も言い返せないよな？w",
    "二度と「挑戦」とか\n口にするなよw",
    "負け犬の遠吠えも\n聞こえないくらい速い逃げ足w",
    "お前の限界、そこ？\n低すぎワロタw",
    "帰ってママに慰めてもらえよw\nミルクでも飲んでろ",
    "その程度で逃げるとか\n義務教育やり直せば？w",
    "IQ2くらいしかなさそうw\nよく生きてこれたな",
    "恥ずかしくないの？\n俺なら恥ずかしくて死ぬわw",
    "逃げた事実は消えないぞ\n一生背負って生きろw",
    "お前の人生、逃げの連続だろ？\n知ってるよw",
    "期待外れにも程がある\nがっかりさせんなよボケ",
    "まさか本当に逃げるとはね...\n見損なったわw",
    "勝負の世界は厳しいなw\nお前には向いてないよ",
    "弱者は去るのみ。\n自然の摂理だなw",
    "今どんな気持ち？ねえ？\n負け犬の気分は？w",
    "逃げる準備だけは\n一人前だなw",
    "ほら、早く行けよ\n目障りなんだよw",
    "お前の席ねーから！\nとっとと帰れw",
    "クッキーに煽られて逃走w\n伝説に残るバカだな",
    "言い訳してみろよ\n「手が滑った」って？w",
    "その程度の知能で\nよくスマホ操作できるなw",
    "アプリ開いた意味あった？\nあ、ないかw",
    "さよなら、敗北者w\n元気でな（嘘だけど）",
    "次会う時は、もう少し\nマシになってろよ？無理かw",
    "逃げるなら、金輪際\n俺の前に現れるな",
    "お前の脳みそ、\n俺のチョコチップより小さいなw",
    "虚しくない？\n俺は最高に楽しいけどw",
    "はいはい、逃走逃走。\nお決まりのパターンだなw",
    "全米が泣いたw\nお前の弱さにw",
    "逃げることは恥だが\n役に立つ...わけねーだろw",
  ];

  /// 逃走演出をトリガー
  void triggerRunAway() {
    _stopTimer();
    _isRunningAway = true;
    
    // ランダムに選出
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _runawayMessages.length;
    _tauntMessage = _runawayMessages[randomIndex];
    // 逃亡画面では自動リセットしない(ユーザーがタップで戻るまで表示し続ける)
    notifyListeners();
  }

  /// 数字を入力
  void handleInput(int row, int col, int num) {
    if (_currentPuzzle == null) return;
    if (_currentPuzzle!.isFixed(row, col)) return;
    if (_gameState.isGameOver) return;

    // 正解チェック
    if (_currentPuzzle!.solution[row][col] == num) {
      _currentPuzzle!.puzzle[row][col] = num;
      
      // マス埋めポイントを加算
      final cellPoints = _getPointsPerCell(_currentPuzzle!.difficulty);
      _gameState = _gameState.copyWith(
        pendingPoints: _gameState.pendingPoints + cellPoints,
      );
      
      // 完成チェック
      if (_isComplete()) {
        _stopTimer();
        _isGameClear = true;
        AudioController().playMascot();
        AudioController().playClear();
        
        // ポイント計算とスコア保存
        _saveScore();
      } else {
        AudioController().playSuccess();

        // 数字が完了したかチェックし、完了していれば次の数字を選択
        if (_isNumberComplete(num)) {
          AudioController().playSubClear(); // 数字完成音を再生
          numberCompletionEvent.value = num; // イベント発火
          _autoSelectNextNumber(num);
        }
      }
    } else {
      // 間違い
      _gameState = _gameState.copyWith(
        errors: _gameState.errors + 1,
        errorCell: {"row": row, "col": col}, // エラーセルを記録
      );
      
      // 2秒後にエラーセルをクリア
      Timer(const Duration(seconds: 2), () {
        _gameState = _gameState.copyWith(clearErrorCell: true);
        notifyListeners();
      });
      
      if (_gameState.errors >= 3) { // 3回ミスでゲームオーバー
        _stopTimer();

        AudioController().playGameOver();
        AudioController().vibrateGameOver(); // 振動フィードバック
      } else {
        AudioController().playError();
      }
    }

    notifyListeners();
  }

  /// 指定した数字がすべて埋まっているか
  bool _isNumberComplete(int num) {
    if (_currentPuzzle == null) return false;
    int count = 0;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_currentPuzzle!.puzzle[i][j] == num) {
          count++;
        }
      }
    }
    return count >= 9;
  }

  /// 次の未完了の数字を自動選択
  void _autoSelectNextNumber(int currentNum) {
    // 1から9までで未完了のものを探す
    // currentNumの次から探し始め、くるっと回る
    for (int i = 1; i <= 9; i++) {
      int next = (currentNum + i - 1) % 9 + 1; // 1-9のサイクル
      if (!_isNumberComplete(next)) {
        // 見つかったら選択
        // ただし、現在選択中の数字がある場合のみ変更する（Lightning/Mode等で重要）
        if (_gameState.selectedNumber != null) {
           _gameState = _gameState.copyWith(selectedNumber: next);
        }
        return;
      }
    }
  }

  /// セルをクリア
  void clearCell(int row, int col) {
    if (_currentPuzzle == null) return;
    if (_currentPuzzle!.isFixed(row, col)) return;

    _currentPuzzle!.puzzle[row][col] = 0;
    notifyListeners();
  }

  /// ヒントを使用
  void useHint() {
    if (_currentPuzzle == null) return;
    if (!_gameState.canUseHint) return;

    // 空のセルを探す
    List<List<int>> emptyCells = [];
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_currentPuzzle!.puzzle[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isEmpty) return;

    // ランダムに1つ選んで埋める
    emptyCells.shuffle();
    var cell = emptyCells.first;
    int row = cell[0];
    int col = cell[1];
    
    _currentPuzzle!.puzzle[row][col] = _currentPuzzle!.solution[row][col];
    _gameState = _gameState.copyWith(hintsUsed: _gameState.hintsUsed + 1);

    // 完成チェック
    if (_isComplete()) {
      _stopTimer();
    }

    notifyListeners();
  }

  /// Lightningモードの切り替え
  Future<void> toggleLightningMode() async {
    final newValue = !_gameState.isLightningMode;
    _gameState = _gameState.copyWith(
      isLightningMode: newValue,
      clearSelectedNumber: !newValue ? false : true,
    );
    notifyListeners();

    if (newValue) {
       triggerTaunt("連続入力だって？\nイキってんじゃねーよw");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLightningMode', newValue);
  }

  /// FastPencilモードの切り替え
  Future<void> toggleFastPencilMode() async {
    final newValue = !_gameState.isFastPencil;
    _gameState = _gameState.copyWith(
      isFastPencil: newValue,
    );
    notifyListeners();

    if (newValue) {
       triggerTaunt("オートメモだぁ？\nラクしようとすんな雑魚w");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFastPencil', newValue);
  }

  /// 数字を選択(Lightning/FastPencilモード用)
  void selectNumber(int num) {
    _gameState = _gameState.copyWith(selectedNumber: num);
    notifyListeners();
  }

  /// 選択中の数字をクリア
  void clearSelectedNumber() {
    _gameState = _gameState.copyWith(clearSelectedNumber: true);
    notifyListeners();
  }

  /// 候補数字を取得(FastPencilモード用)
  List<int> getCandidates(int row, int col) {
    if (_currentPuzzle == null) return [];
    return _engine.getCandidates(_currentPuzzle!.puzzle, row, col);
  }

  /// パズルが完成しているかチェック
  bool _isComplete() {
    if (_currentPuzzle == null) return false;
    return _engine.isComplete(_currentPuzzle!.puzzle);
  }

  /// 各数字の残り個数を取得
  Map<int, int> getRemainingCounts() {
    if (_currentPuzzle == null) return {};

    Map<int, int> counts = {};
    for (int num = 1; num <= 9; num++) {
      int count = 0;
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          if (_currentPuzzle!.puzzle[i][j] == num) {
            count++;
          }
        }
      }
      counts[num] = 9 - count;
    }
    return counts;
  }

  /// マスあたりのポイントを取得
  int _getPointsPerCell(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 100;
      case Difficulty.medium:
        return 200;
      case Difficulty.hard:
        return 500;
      case Difficulty.expert:
        return 3000;
      case Difficulty.extreme:
        return 5000;
    }
  }

  /// 時間ボーナスを計算
  /// 
  /// 難易度ごとに目標時間を設定し、早くクリアするほど多くのボーナスを獲得
  /// 目標時間の50%以下: 最大ボーナス
  /// 目標時間: ボーナスなし
  /// 目標時間の150%以上: ペナルティ
  int _calculateTimeBonus(Difficulty difficulty, int clearTimeSeconds) {
    // 難易度ごとの目標時間(秒)
    int targetTime;
    int maxBonus;
    
    switch (difficulty) {
      case Difficulty.easy:
        targetTime = 300; // 5分
        maxBonus = 1000;
        break;
      case Difficulty.medium:
        targetTime = 600; // 10分
        maxBonus = 3000;
        break;
      case Difficulty.hard:
        targetTime = 900; // 15分
        maxBonus = 8000;
        break;
      case Difficulty.expert:
        targetTime = 1200; // 20分
        maxBonus = 30000;
        break;
      case Difficulty.extreme:
        targetTime = 1800; // 30分
        maxBonus = 50000;
        break;
    }
    
    // 時間比率を計算 (clearTime / targetTime)
    double timeRatio = clearTimeSeconds / targetTime;
    
    if (timeRatio <= 0.5) {
      // 目標時間の50%以下: 最大ボーナス
      return maxBonus;
    } else if (timeRatio <= 1.0) {
      // 目標時間以内: 線形にボーナス減少
      // timeRatio 0.5 -> maxBonus, timeRatio 1.0 -> 0
      return (maxBonus * (1.0 - timeRatio) / 0.5).round();
    } else if (timeRatio <= 1.5) {
      // 目標時間の150%以内: ボーナスなし
      return 0;
    } else {
      // 目標時間の150%超過: ペナルティ
      // 最大でベースポイントの10%をペナルティ
      int basePenalty = (_getPointsPerCell(difficulty) * 5).round();
      int penalty = (basePenalty * (timeRatio - 1.5)).round();
      return -penalty.clamp(0, basePenalty * 2);
    }
  }

  /// スコアを保存
  Future<void> _saveScore() async {
    if (_currentPuzzle == null) return;

    // スコアが無効化されている場合は保存しない
    if (_gameState.isScoreInvalid) {
      print("Score is invalid (mascot clicked 10 times), not saving.");
      return;
    }

    // 基本ポイント + 時間ボーナス
    final basePoints = _gameState.pendingPoints;
    final timeBonus = _calculateTimeBonus(_currentPuzzle!.difficulty, _gameState.time);
    int totalPoints = (basePoints + timeBonus).clamp(0, double.infinity).toInt();

    // デイリーミッションボーナス判定
    bool isDailyBonusApplied = false;
    if (_isDailyMission && _dailyDate != null) {
      final now = DateTime.now();
      // 年月日が一致するかチェック
      final isToday = now.year == _dailyDate!.year && 
                      now.month == _dailyDate!.month && 
                      now.day == _dailyDate!.day;
      
      if (isToday) {
        // 当日なら10倍ボーナス！
        totalPoints *= 10;
        isDailyBonusApplied = true;
        
        // 煽り（ポジティブ？）
        triggerTaunt("今日中にクリアとはな...\n褒めてやるよ、10倍界王拳だ！");
        AudioController().playMascot(); // 追加で鳴らす
      }
      
      // デイリークリア履歴を保存
      final dateId = "${_dailyDate!.year}-${_dailyDate!.month.toString().padLeft(2, '0')}-${_dailyDate!.day.toString().padLeft(2, '0')}";
      await RankingRepository().saveDailyClear(dateId, totalPoints);
    }
    
    // UI表示用に保存
    _lastTotalScore = totalPoints;
    notifyListeners();
    
    // Repositoryを通じてIDを取得 (Auth or Local UUID)
    final userId = await RankingRepository().getUserId();
    final username = _gameState.username.isEmpty ? 'Player' : _gameState.username;

    final score = ScoreModel(
      id: const Uuid().v4(), // Local ID (Unique per score)
      userId: userId,
      username: username,
      difficulty: _currentPuzzle!.difficulty.displayName, // "ふつう", "むずかしい" etc
      points: totalPoints,
      clearTime: _gameState.time,
      createdAt: DateTime.now(),
    );

    // Repositoryを通じて保存 (Local & Remote)
    await RankingRepository().addScore(score);
    
    // ユーザー統計を更新
    await RankingRepository().updateUserStats(
      userId: userId,
      username: username,
      pointsToAdd: totalPoints,
      difficulty: _currentPuzzle!.difficulty,
      clearTime: _gameState.time,
    );
    
    print("Score Saved: Base=$basePoints, TimeBonus=$timeBonus, Total=$totalPoints, Time=${_gameState.time}s");
    
    // Play Gamesにスコアを送信
    await _submitToPlayGames(totalPoints);
    
    // 実績を解除
    await _unlockAchievements();
  }
  
  /// Play Gamesにスコアを送信
  Future<void> _submitToPlayGames(int points) async {
    try {
      final playGames = PlayGamesService();
      
      // サインインしていない場合は送信しない
      if (!playGames.isSignedIn) {
        print('Play Games: サインインしていないためスコア送信をスキップ');
        return;
      }
      
      // リーダーボードにスコアを送信
      final success = await playGames.submitScore(
        leaderboardId: PlayGamesConstants.leaderboardTotalScore,
        score: points,
      );
      
      if (success) {
        print('Play Games: スコア送信成功 ($points pts)');
      }
    } catch (e) {
      print('Play Games スコア送信エラー: $e');
    }
  }
  
  /// 実績を解除
  Future<void> _unlockAchievements() async {
    try {
      final playGames = PlayGamesService();
      
      // サインインしていない場合は解除しない
      if (!playGames.isSignedIn) {
        print('Play Games: サインインしていないため実績解除をスキップ');
        return;
      }
      
      // 初クリア実績を解除
      await playGames.unlockAchievement(
        achievementId: PlayGamesConstants.achievementFirstClear,
      );
      print('Play Games: 初クリア実績解除');
      
      // スピードマスター(5分以内)
      if (_gameState.time <= 300) { // 300秒 = 5分
        await playGames.unlockAchievement(
          achievementId: PlayGamesConstants.achievementSpeedMaster,
        );
        print('Play Games: スピードマスター実績解除');
      }
      
      // 完璧主義者(ミスなし)
      if (_gameState.errors == 0) {
        await playGames.unlockAchievement(
          achievementId: PlayGamesConstants.achievementPerfectionist,
        );
        print('Play Games: 完璧主義者実績解除');
      }
    } catch (e) {
      print('Play Games 実績解除エラー: $e');
    }
  }


  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
