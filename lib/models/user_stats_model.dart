import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー統計データモデル
/// 累積ポイント、難易度別ベストタイムを管理
class UserStatsModel {
  final String userId;
  final String username;
  final int totalPoints; // 累積ポイント
  final Map<String, int> bestTimes; // 難易度別ベストタイム {"やわクッキー": 120, ...}
  final DateTime updatedAt;

  UserStatsModel({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.bestTimes,
    required this.updatedAt,
  });

  /// Map (Firestore/Sqflite保存用) に変換
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'totalPoints': totalPoints,
      'bestTimes': bestTimes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Firestoreから生成
  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // updatedAtはTimestamp型またはString型の可能性がある
    DateTime updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(data['updatedAt']) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }
    
    // bestTimesをMap<String, int>に変換
    Map<String, int> bestTimes = {};
    if (data['bestTimes'] != null) {
      final rawBestTimes = data['bestTimes'] as Map<String, dynamic>;
      rawBestTimes.forEach((key, value) {
        bestTimes[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }
    
    return UserStatsModel(
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown',
      totalPoints: data['totalPoints'] ?? 0,
      bestTimes: bestTimes,
      updatedAt: updatedAt,
    );
  }

  /// Mapから生成 (Local DB用)
  factory UserStatsModel.fromMap(Map<String, dynamic> map) {
    // bestTimesはJSON文字列として保存されている可能性がある
    Map<String, int> bestTimes = {};
    if (map['bestTimes'] != null) {
      if (map['bestTimes'] is String) {
        // JSON文字列からパース
        try {
          final decoded = map['bestTimes'] as String;
          // 簡易的なパース (実際にはjson.decodeを使用すべき)
          // ここでは直接Mapとして扱う
          bestTimes = {};
        } catch (e) {
          bestTimes = {};
        }
      } else if (map['bestTimes'] is Map) {
        final rawBestTimes = map['bestTimes'] as Map<String, dynamic>;
        rawBestTimes.forEach((key, value) {
          bestTimes[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
      }
    }
    
    return UserStatsModel(
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Unknown',
      totalPoints: map['totalPoints'] ?? 0,
      bestTimes: bestTimes,
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// コピーを作成
  UserStatsModel copyWith({
    String? userId,
    String? username,
    int? totalPoints,
    Map<String, int>? bestTimes,
    DateTime? updatedAt,
  }) {
    return UserStatsModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      totalPoints: totalPoints ?? this.totalPoints,
      bestTimes: bestTimes ?? this.bestTimes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
