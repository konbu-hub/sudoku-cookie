import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/score_model.dart';
import '../repositories/ranking_repository.dart';
import '../services/auth_service.dart';
import '../controllers/audio_controller.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

enum RankingSort { points, time }

class RankingScreen extends StatefulWidget {
  final bool isTab;
  const RankingScreen({super.key, this.isTab = false});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RankingRepository _repository = RankingRepository();
  
  // Data States
  List<ScoreModel> _globalScores = [];
  List<ScoreModel> _localScores = [];
  int _runAwayCount = 0;
  bool _isLoading = true;
  
  // New Runaway Ranking Data
  List<Map<String, dynamic>> _runAwayRanking = [];
  bool _showRunAwayRanking = false;
  
  // Filters
  String _selectedDifficulty = 'すべて';
  RankingSort _sortBy = RankingSort.points;
  
  final List<String> _difficulties = [
    'すべて',
    'やわクッキー',
    '普通クッキー',
    '堅クッキー',
    'バリ堅クッキー',
    '石'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController().ensureTitleBgm();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _repository.fetchGlobalRanking(),
      _repository.fetchLocalHistory(),
      _repository.getRunAwayCount(),
      _repository.fetchGlobalRunAwayRanking(),
    ]);

    if (mounted) {
      setState(() {
        _globalScores = results[0] as List<ScoreModel>;
        _localScores = results[1] as List<ScoreModel>;
        _runAwayCount = results[2] as int;
        _runAwayRanking = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      
      // DEBUG: データ取得状況をログ出力
      print('DEBUG [RankingScreen]: Global Scores Count: ${_globalScores.length}');
      print('DEBUG [RankingScreen]: Local Scores Count: ${_localScores.length}');
      print('DEBUG [RankingScreen]: RunAway Count: $_runAwayCount');
      print('DEBUG [RankingScreen]: RunAway Ranking Count: ${_runAwayRanking.length}');
      if (_globalScores.isNotEmpty) {
        print('DEBUG [RankingScreen]: Sample Global Score: ${_globalScores.first.username} - ${_globalScores.first.points}pts');
      }
    }
  }

  // ... dispose ...

  List<ScoreModel> _filterAndSortScores(List<ScoreModel> scores) {
    if (_showRunAwayRanking) return []; // 逃亡ランキング時は使用しない

    var filtered = scores;
    if (_selectedDifficulty != 'すべて') {
      filtered = filtered.where((s) => s.difficulty == _selectedDifficulty).toList();
    }
    
    // ユーザーごとのベストスコアのみを残す
    final Map<String, ScoreModel> bestScorePerUser = {};
    for (final score in filtered) {
      final userId = score.userId;
      if (!bestScorePerUser.containsKey(userId) ||
          score.points > bestScorePerUser[userId]!.points) {
        bestScorePerUser[userId] = score;
      }
    }
    filtered = bestScorePerUser.values.toList();
    
    filtered.sort((a, b) {
      if (_sortBy == RankingSort.points) {
        return b.points.compareTo(a.points);
      } else {
        return a.clearTime.compareTo(b.clearTime);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.isTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AudioController().playReturn();
            Navigator.of(context).pop();
          },
        ),
        automaticallyImplyLeading: !widget.isTab,
        title: const Text('ランキング'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.public), text: 'グローバル'),
            Tab(icon: Icon(Icons.analytics), text: 'マイサマリー'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // グローバルタブ
          Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _showRunAwayRanking
                        ? _buildRunAwayRankingList()
                        : _buildRankingList(_filterAndSortScores(_globalScores), isLocal: false),
              ),
            ],
          ),
          // マイサマリータブ
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPlaySummary(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ランキング種別切り替え (VS 逃亡王)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('ハイスコア'),
                icon: Icon(Icons.emoji_events),
              ),
              ButtonSegment(
                value: true,
                label: Text('逃亡王'),
                icon: Icon(Icons.directions_run),
              ),
            ],
            selected: {_showRunAwayRanking},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _showRunAwayRanking = newSelection.first;
              });
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          
          if (!_showRunAwayRanking) ...[
            const SizedBox(height: 12),
            // ソートとフィルター
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      labelText: '難易度を選択',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: _difficulties.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDifficulty = newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // ソート切り替え (アイコンのみで省スペース化)
                ToggleButtons(
                  isSelected: [_sortBy == RankingSort.points, _sortBy == RankingSort.time],
                  onPressed: (index) {
                    setState(() {
                      _sortBy = index == 0 ? RankingSort.points : RankingSort.time;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  children: const [
                    Tooltip(message: 'ポイント順', child: Icon(Icons.stars)),
                    Tooltip(message: 'タイム順', child: Icon(Icons.timer)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRunAwayRankingList() {
    if (_runAwayRanking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'まだ逃げ出した人はいません\n（あるいはデータがありません）',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final currentUserId = AuthService().currentUser?.uid;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _runAwayRanking.length,
        itemBuilder: (context, index) {
          final data = _runAwayRanking[index];
          final rank = index + 1;
          final isCurrentUser = data['userId'] == currentUserId;
          // Firestore Timestamp to DateTime conversion handling
          DateTime? updatedAt;
          if (data['updatedAt'] != null) {
             if (data['updatedAt'] is Timestamp) {
               updatedAt = (data['updatedAt'] as Timestamp).toDate();
             } else if (data['updatedAt'] is String) {
               updatedAt = DateTime.tryParse(data['updatedAt']);
             }
          }

          return Card(
            elevation: isCurrentUser ? 4 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrentUser 
                ? Colors.red.withOpacity(0.1) 
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isCurrentUser
                  ? const BorderSide(color: Colors.red, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              leading: SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      data['username'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'あんた',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: updatedAt != null 
                  ? Text('最終逃亡: ${_formatDate(updatedAt)}') 
                  : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data['count']}回',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ... _buildRankingList (existing) ...
  // ... _buildScoreCard (existing) ...
  // ... _buildInfoChip (existing) ...
  // ... _formatTime (existing) ...

  String _formatDate(DateTime date) {
    // 強制的にJST (UTC+9) で表示
    // toUtc()でUTCにし、そこから9時間足す
    final jstDate = date.toUtc().add(const Duration(hours: 9));
    return DateFormat('yyyy/MM/dd HH:mm').format(jstDate);
  }

  Widget _buildRankingList(List<ScoreModel> scores, {required bool isLocal}) {
    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isLocal ? 'まだ記録がありません' : 'ランキングデータがありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final currentUserId = AuthService().currentUser?.uid;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scores.length,
        itemBuilder: (context, index) {
          final score = scores[index];
          final isCurrentUser = score.userId == currentUserId;
          final rank = index + 1;
          
          return _buildScoreCard(score, rank, isCurrentUser);
        },
      ),
    );
  }

  Widget _buildScoreCard(ScoreModel score, int rank, bool isCurrentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color? rankColor;
    IconData? rankIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400];
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[300];
      rankIcon = Icons.emoji_events;
    }

    return Card(
      elevation: isCurrentUser ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentUser 
          ? (isDark 
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.indigo.shade50) // ライトモード: 淡いインディゴ
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentUser
            ? BorderSide(
                color: isDark ? Theme.of(context).colorScheme.primary : Colors.indigo.shade700,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ランク表示
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  if (rankIcon != null)
                    Icon(rankIcon, color: rankColor, size: 32)
                  else
                    Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (rank <= 3)
                    Text(
                      rank == 1 ? '1st' : rank == 2 ? '2nd' : '3rd',
                      style: TextStyle(
                        fontSize: 12,
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // ユーザー情報とスコア
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          score.username,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.primary : Colors.indigo.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'あんた',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.stars,
                        '${score.points}pt',
                        Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.timer,
                        _formatTime(score.clearTime),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.cookie,
                        score.difficulty,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(score.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPlaySummary() {
    // ... existing content start ...
    if (_localScores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'まだプレイ記録がありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'ゲームをクリアして記録を残そう！',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // 統計計算
    final totalGames = _localScores.length;
    final totalTime = _localScores.fold<int>(0, (sum, score) => sum + score.clearTime);
    final totalPoints = _localScores.fold<int>(0, (sum, score) => sum + score.points);
    
    // 難易度別の統計
    final difficultyStats = <String, Map<String, dynamic>>{};
    for (var difficulty in _difficulties.skip(1)) { // 'すべて'をスキップ
      final diffScores = _localScores.where((s) => s.difficulty == difficulty).toList();
      if (diffScores.isNotEmpty) {
        difficultyStats[difficulty] = {
          'count': diffScores.length,
          'bestTime': diffScores.map((s) => s.clearTime).reduce((a, b) => a < b ? a : b),
          'bestScore': diffScores.map((s) => s.points).reduce((a, b) => a > b ? a : b),
        };
      }
    }

    // 最近のプレイ履歴
    final recentScores = _localScores.take(5).toList();

    // グローバルランキング内での最高順位を探す
    final currentUser = AuthService().currentUser;
    int? globalRank;
    if (currentUser != null) {
      final userIndex = _globalScores.indexWhere((s) => s.userId == currentUser.uid);
      if (userIndex != -1) {
        globalRank = userIndex + 1;
      }
    }

    // 逃亡ランキング内での順位を探す
    int? runawayRank;
    if (currentUser != null && _runAwayRanking.isNotEmpty) {
      final userIndex = _runAwayRanking.indexWhere((data) => data['userId'] == currentUser.uid);
      if (userIndex != -1) {
        runawayRank = userIndex + 1;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザープロフィールヘッダー
            Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final username = gameProvider.gameState.username.isEmpty 
                    ? 'プレイヤー' 
                    : gameProvider.gameState.username;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, size: 35, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'プレイヤー名',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              username,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (globalRank != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.emoji_events, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              '世界 $globalRank位',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (globalRank != null && runawayRank != null)
                                      const SizedBox(width: 8),
                                    if (runawayRank != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.directions_run, size: 14, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              '逃亡王 $runawayRank位',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (globalRank != null && globalRank <= 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.workspace_premium,
                            size: 40,
                            color: globalRank == 1 
                                ? Colors.amber 
                                : (globalRank == 2 ? Colors.grey[300] : Colors.orange[300]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // 総合統計カード
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          '総合統計',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('総プレイ回数', '$totalGames回', Icons.games, Colors.blue),
                        _buildStatItem('総プレイ時間', _formatTime(totalTime), Icons.timer, Colors.green),
                        _buildStatItem('総獲得ポイント', '${totalPoints}pt', Icons.stars, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 逃亡回数（恥の記録）
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_run, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'ビビって逃げた回数:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_runAwayCount回',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 難易度別統計
            const Text(
              '難易度別ベスト記録',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...difficultyStats.entries.map((entry) {
              final difficulty = entry.key;
              final stats = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cookie, color: _getDifficultyColor(difficulty), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            difficulty,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${stats['count']}回クリア',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatChip(
                              Icons.timer,
                              'ベストタイム',
                              _formatTime(stats['bestTime']),
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatChip(
                              Icons.stars,
                              '最高スコア',
                              '${stats['bestScore']}pt',
                              Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            
            // 最近のプレイ履歴
            Row(
              children: [
                const Text(
                  '最近のプレイ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: 全履歴を表示するダイアログを開く
                  },
                  child: const Text('すべて見る'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentScores.map((score) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDifficultyColor(score.difficulty).withOpacity(0.2),
                    child: Icon(
                      Icons.cookie,
                      color: _getDifficultyColor(score.difficulty),
                      size: 20,
                    ),
                  ),
                  title: Text(score.difficulty),
                  subtitle: Text(_formatDate(score.createdAt)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.points}pt',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatTime(score.clearTime),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (difficulty) {
      case 'やわクッキー':
        return isDark ? Colors.green : Colors.green.shade700;
      case '普通クッキー':
        return isDark ? Colors.blue : Colors.blue.shade800;
      case '堅クッキー':
        return isDark ? Colors.orange : Colors.orange.shade900;
      case 'バリ堅クッキー':
        return isDark ? Colors.red : Colors.red.shade900;
      case '石':
        return isDark ? Colors.purple : Colors.deepPurple.shade900; // ライトモード: 濃い紫
      default:
        return isDark ? Colors.grey : Colors.grey.shade800;
    }
  }
}
