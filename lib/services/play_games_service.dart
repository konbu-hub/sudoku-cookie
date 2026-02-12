import 'dart:io';
import 'package:games_services/games_services.dart';

/// Google Play Gamesサービスのラッパークラス
/// 
/// サインイン、リーダーボード、実績の管理を行う
class PlayGamesService {
  static final PlayGamesService _instance = PlayGamesService._internal();
  factory PlayGamesService() => _instance;
  PlayGamesService._internal();

  bool _isSignedIn = false;
  
  /// サインイン状態を取得
  bool get isSignedIn => _isSignedIn;

  /// Play Gamesにサインイン
  Future<bool> signIn() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await GamesServices.signIn();
      // games_services 4.x では String を返す
      _isSignedIn = result == 'success';
      return _isSignedIn;
    } catch (e) {
      print('Play Games サインインエラー: $e');
      _isSignedIn = false;
      return false;
    }
  }

  /// サインアウト
  /// games_services 4.x ではサインアウトメソッドがないため、状態のみリセット
  Future<void> signOut() async {
    if (!Platform.isAndroid) return;
    _isSignedIn = false;
  }

  /// リーダーボードにスコアを送信
  /// 
  /// [leaderboardId] リーダーボードID(Google Play Consoleで作成)
  /// [score] 送信するスコア
  Future<bool> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    if (!Platform.isAndroid) return false;

    if (!_isSignedIn) {
      print('Play Games: サインインしていないためスコア送信をスキップ');
      // サインインを試みる
      await signIn();
      if (!_isSignedIn) {
        return false;
      }
    }

    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          value: score,
        ),
      );
      return true;
    } catch (e) {
      print('スコア送信エラー: $e');
      return false;
    }
  }

  /// リーダーボードを表示
  /// 
  /// [leaderboardId] 表示するリーダーボードID
  Future<void> showLeaderboard({String? leaderboardId}) async {
    if (!Platform.isAndroid) return;

    if (!_isSignedIn) {
      print('Play Games: サインインしていないためリーダーボード表示をスキップ');
      // サインインを試みる
      await signIn();
      if (!_isSignedIn) {
        return;
      }
    }

    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: leaderboardId ?? '',
        androidLeaderboardID: leaderboardId ?? '',
      );
    } catch (e) {
      print('リーダーボード表示エラー: $e');
    }
  }

  /// 実績を解除
  /// 
  /// [achievementId] 実績ID(Google Play Consoleで作成)
  /// [percentComplete] 達成率(0-100)、100で解除
  Future<bool> unlockAchievement({
    required String achievementId,
    int percentComplete = 100,
  }) async {
    if (!Platform.isAndroid) return false;

    if (!_isSignedIn) {
      print('Play Games: サインインしていないため実績解除をスキップ');
      // サインインを試みる
      await signIn();
      if (!_isSignedIn) {
        return false;
      }
    }

    try {
      await GamesServices.unlock(
        achievement: Achievement(
          androidID: achievementId,
          percentComplete: percentComplete.toDouble(),
          // iOSIDが必須かもしれないが、Androidのみの想定
        ),
      );
      return true;
    } catch (e) {
      print('実績解除エラー: $e');
      return false;
    }
  }

  /// 実績一覧を表示
  Future<void> showAchievements() async {
    if (!Platform.isAndroid) return;

    if (!_isSignedIn) {
      print('Play Games: サインインしていないため実績表示をスキップ');
      // サインインを試みる
      await signIn();
      if (!_isSignedIn) {
        return;
      }
    }

    try {
      await GamesServices.showAchievements();
    } catch (e) {
      print('実績表示エラー: $e');
    }
  }
}
