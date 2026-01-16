import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_model.dart';
import '../models/user_stats_model.dart';
import '../models/sudoku_puzzle.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class RankingRepository {
  static final RankingRepository _instance = RankingRepository._internal();
  factory RankingRepository() => _instance;
  RankingRepository._internal();

  Database? _localDb;
  final FirebaseFirestore? _firestore = _safeGetFirestore();

  // Firestore初期化の安全策（設定ファイルがない場合などのエラー回避）
  static FirebaseFirestore? _safeGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      print("Firestore not initialized (Offline Mode): $e");
      return null;
    }
  }

  /// データベース初期化
  Future<void> init() async {
    if (_localDb != null) return;
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sudoku_scores.db');

    _localDb = await openDatabase(
      path,
      version: 2, // バージョンを上げる
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scores(
            id TEXT PRIMARY KEY,
            userId TEXT,
            username TEXT,
            difficulty TEXT,
            points INTEGER,
            clearTime INTEGER,
            createdAt TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE user_stats(
            userId TEXT PRIMARY KEY,
            username TEXT,
            totalPoints INTEGER,
            bestTimes TEXT,
            updatedAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE user_stats(
              userId TEXT PRIMARY KEY,
              username TEXT,
              totalPoints INTEGER,
              bestTimes TEXT,
              updatedAt TEXT
            )
          ''');
        }
      },
    );
  }

  /// スコア追加 (Local & Remote)
  Future<void> addScore(ScoreModel score) async {
    await init();
    
    // 1. Local Save
    await _localDb!.insert(
      'scores',
      score.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Remote Save (if available)
    if (_firestore != null) {
      try {
        await _firestore!.collection('global_scores').add({
          ...score.toMap(),
          'createdAt': FieldValue.serverTimestamp(), // Server Time優先
        });
      } catch (e) {
        print("Failed to sync to Firestore: $e");
      }
    }
  }

  /// ローカル履歴取得
  Future<List<ScoreModel>> fetchLocalHistory() async {
    await init();
    final List<Map<String, dynamic>> maps = await _localDb!.query(
      'scores',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => ScoreModel.fromMap(maps[i]));
  }

  /// ローカル履歴を削除
  Future<void> clearLocalHistory() async {
    await init();
    await _localDb!.delete('scores');
  }

  /// リモートデータ（Firestore）を削除
  Future<void> clearRemoteData() async {
    if (_firestore == null) return;

    try {
      final userId = await getUserId();
      
      // 1. スコア履歴の削除 (global_scores)
      final scoresQuery = await _firestore!
          .collection('global_scores')
          .where('userId', isEqualTo: userId)
          .get();
      
      final batch = _firestore!.batch();
      for (var doc in scoresQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. 逃亡履歴の削除 (global_runaways)
      final runawayRef = _firestore!.collection('global_runaways').doc(userId);
      batch.delete(runawayRef);
      
      // 3. 逃亡回数のローカルデータもリセット
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('run_away_count');

      await batch.commit();
      print("Remote data cleared for user: $userId");
    } catch (e) {
      print("Failed to clear remote data: $e");
      // エラーでもローカル削除は続行できるようにスローはしない、または呼び出し元でハンドリング
    }
  }


  /// グローバルランキング取得 (TOP 50)
  Future<List<ScoreModel>> fetchGlobalRanking() async {
    // Offline Mode -> Return Empty (Real data only)
    if (_firestore == null) {
      print('DEBUG [RankingRepository]: Firestore is null, returning empty list');
      return [];
    }

    try {
      final querySnapshot = await _firestore!
          .collection('global_scores')
          .orderBy('points', descending: true)
          .limit(50)
          .get();

      final scores = querySnapshot.docs
          .map((doc) => ScoreModel.fromFirestore(doc))
          .toList();
      
      print('DEBUG [RankingRepository]: Fetched ${scores.length} global scores from Firestore');
      return scores;
    } catch (e) {
      print("Firestore Fetch Error: $e");
      return []; // Return empty on error
    }
  }

  /// ダミーデータ生成（廃止）
  List<ScoreModel> _generateMockRanking() {
    return [];
  }

  // ---------------------------------------------------------------------------
  // ユーザー統計管理 (User Stats Management)
  // ---------------------------------------------------------------------------

  /// ユーザー統計を更新
  Future<void> updateUserStats({
    required String userId,
    required String username,
    required int pointsToAdd,
    required Difficulty difficulty,
    required int clearTime,
  }) async {
    await init();

    // 1. ローカルデータベースの更新
    final existing = await _localDb!.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    Map<String, int> bestTimes = {};
    int totalPoints = pointsToAdd;

    if (existing.isNotEmpty) {
      final current = existing.first;
      totalPoints = (current['totalPoints'] as int) + pointsToAdd;
      
      // bestTimesをパース
      if (current['bestTimes'] != null && current['bestTimes'] != '') {
        try {
          final decoded = json.decode(current['bestTimes'] as String) as Map<String, dynamic>;
          bestTimes = decoded.map((key, value) => MapEntry(key, value as int));
        } catch (e) {
          print('Failed to parse bestTimes: $e');
        }
      }
    }

    // 難易度別ベストタイムを更新
    final difficultyName = difficulty.displayName;
    if (!bestTimes.containsKey(difficultyName) || clearTime < bestTimes[difficultyName]!) {
      bestTimes[difficultyName] = clearTime;
    }

    final statsData = {
      'userId': userId,
      'username': username,
      'totalPoints': totalPoints,
      'bestTimes': json.encode(bestTimes),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _localDb!.insert(
      'user_stats',
      statsData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 2. Firestoreへの同期
    if (_firestore != null) {
      try {
        await _firestore!.collection('user_stats').doc(userId).set({
          'userId': userId,
          'username': username,
          'totalPoints': totalPoints,
          'bestTimes': bestTimes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Failed to sync user stats to Firestore: $e');
      }
    }
  }

  /// 累積ポイントランキングを取得 (TOP 50)
  Future<List<UserStatsModel>> fetchGlobalRankingByTotalPoints() async {
    if (_firestore == null) {
      print('DEBUG [RankingRepository]: Firestore is null, returning empty list');
      return [];
    }

    try {
      final querySnapshot = await _firestore!
          .collection('user_stats')
          .orderBy('totalPoints', descending: true)
          .limit(50)
          .get();

      final stats = querySnapshot.docs
          .map((doc) => UserStatsModel.fromFirestore(doc))
          .toList();
      
      print('DEBUG [RankingRepository]: Fetched ${stats.length} user stats from Firestore');
      return stats;
    } catch (e) {
      print('Firestore User Stats Fetch Error: $e');
      return [];
    }
  }

  /// 特定ユーザーの統計を取得
  Future<UserStatsModel?> getUserStats(String userId) async {
    await init();

    // ローカルから取得
    final result = await _localDb!.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) return null;

    return UserStatsModel.fromMap(result.first);
  }

  /// ユーザー名を更新（ローカルの全スコア & Firestore）
  Future<void> updateUsername(String userId, String newUsername) async {
    await init();
    
    // 1. ローカルデータベースの更新
    await _localDb!.update(
      'scores',
      {'username': newUsername},
      where: 'userId = ?',
      whereArgs: [userId],
    );

    // 2. Firestoreの更新 (サインインしている場合)
    if (_firestore != null) {
      try {
        // 2-1. global_scores コレクションの更新
        final querySnapshot = await _firestore!
            .collection('global_scores')
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final batch = _firestore!.batch();
          for (var doc in querySnapshot.docs) {
            batch.update(doc.reference, {'username': newUsername});
          }
          await batch.commit();
        }

        // 2-2. global_runaways コレクションの更新（逃亡王ランキング）
        final runawayDoc = await _firestore!
            .collection('global_runaways')
            .doc(userId)
            .get();

        if (runawayDoc.exists) {
          await _firestore!
              .collection('global_runaways')
              .doc(userId)
              .update({'username': newUsername});
        }
      } catch (e) {
        print("Failed to update username in Firestore: $e");
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 逃亡回数計測 (Chickened Out Count)
  // ---------------------------------------------------------------------------

  /// 逃亡回数を取得
  Future<int> getRunAwayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('run_away_count') ?? 0;
  }

  /// 逃亡回数をインクリメント (Local & Remote)
  Future<void> incrementRunAwayCount() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt('run_away_count') ?? 0;
    int newValue = current + 1;
    await prefs.setInt('run_away_count', newValue);

    // Sync to Firestore
    if (_firestore != null) {
      try {
        final userId = await getUserId();
        final username = await _getUsername();
        
        await _firestore!.collection('global_runaways').doc(userId).set({
          'userId': userId,
          'username': username,
          'count': newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print("Failed to sync run away count: $e");
      }
    }
  }
  
  /// グローバル逃亡ランキング取得 (TOP 50)
  Future<List<Map<String, dynamic>>> fetchGlobalRunAwayRanking() async {
    if (_firestore == null) {
      return []; // Offline
    }

    try {
      final querySnapshot = await _firestore!
          .collection('global_runaways')
          .orderBy('count', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Firestore RunAway Fetch Error: $e");
      return []; // Error (Network etc) calls return empty
    }
  }

  List<Map<String, dynamic>> _generateMockRunAwayRanking() {
    return [];
  }

  /// ユーザーIDを取得 (Auth UID or Local UUID)
  Future<String> getUserId() async {
    // 1. AuthService (Google Auth)
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }

    // 2. Local Persistent ID
    final prefs = await SharedPreferences.getInstance();
    String? localId = prefs.getString('local_user_id');
    
    if (localId == null) {
      localId = Uuid().v4();
      await prefs.setString('local_user_id', localId!);
    }
    
    return localId!;
  }
  
  Future<String> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Player';
  }
}
