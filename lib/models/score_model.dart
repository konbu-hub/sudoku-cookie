import 'package:cloud_firestore/cloud_firestore.dart';

/// スコアデータモデル
/// Local DB (sqflite) と Remote DB (Firestore) の両方で使用
class ScoreModel {
  final String? id; // Firestore Doc ID (LocalではUUID文字列として使用推奨)
  final String userId; // ユーザー識別子 (Auth未実装時はUUID等)
  final String username;
  final String difficulty;
  final int points;
  final int clearTime; // 秒
  final DateTime createdAt;

  ScoreModel({
    this.id,
    required this.userId,
    required this.username,
    required this.difficulty,
    required this.points,
    required this.clearTime,
    required this.createdAt,
  });

  /// Map (Firestore/Sqflite保存用) に変換
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'difficulty': difficulty,
      'points': points,
      'clearTime': clearTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Firestoreから生成
  factory ScoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // createdAtはTimestamp型またはString型の可能性がある
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    
    return ScoreModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Unknown',
      difficulty: data['difficulty'] ?? 'Normal',
      points: data['points'] ?? 0,
      clearTime: data['clearTime'] ?? 0,
      createdAt: createdAt,
    );
  }

  /// Mapから生成 (Local DB用)
  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    return ScoreModel(
      id: map['id']?.toString(), // Local DBではIDがある場合がある
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Unknown',
      difficulty: map['difficulty'] ?? 'Normal',
      points: map['points'] ?? 0,
      clearTime: map['clearTime'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
