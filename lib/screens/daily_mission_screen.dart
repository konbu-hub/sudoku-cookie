import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../controllers/audio_controller.dart';
import '../providers/game_provider.dart';
import '../repositories/ranking_repository.dart';
import 'game_screen.dart';

class DailyMissionScreen extends StatefulWidget {
  const DailyMissionScreen({super.key});

  @override
  State<DailyMissionScreen> createState() => _DailyMissionScreenState();
}

class _DailyMissionScreenState extends State<DailyMissionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _clearedDates = []; // YYYY-MM-DD
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadClearedDates();
    
    // BGM再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
       AudioController().playDailyBgm();
    });
  }

  Future<void> _loadClearedDates() async {
    final dates = await RankingRepository().getClearedDates(_focusedDay);
    if (mounted) {
      setState(() {
        _clearedDates = dates;
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      // 未来の日付は選択不可
      if (selectedDay.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("未来のことは誰にもわからん。\n焦るなよw")),
        );
        return;
      }

      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _startGame() async {
    if (_selectedDay == null) return;
    
    // クリア済みチェック
    final dateId = "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
    if (_clearedDates.contains(dateId)) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("もうクリアしてるだろ？\n記憶力ないのか？w")),
        );
        return;
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    await gameProvider.startDailyMission(_selectedDay!);

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
      
      // ゲームから戻ってきたらBGMをDailyに戻す (GameScreenでMainに変わっている可能性があるため... と思ったがGame側でDailyBGM再生してるなら変わらないはず。でも通常Gameから戻ってくるケースも考えると明示した方が安全)
      // 実際はDailyMissionモードでGameScreenに行けばDailyBGMのまま戻ってくるはずだが、念の為。
      AudioController().playDailyBgm();

      // ゲームから戻ってきたらクリア状況を更新
      if (result == true) {
        _loadClearedDates();
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("やるじゃねぇか。\n明日はどうかな？w")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark Background
      appBar: AppBar(
        title: Text(
          'DAILY MISSION',
          style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                // マスコットエリア（カレンダー上部）
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/cookie_mascot_evil.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text(
                            "毎日サボらずやれよ？\n継続こそ力なり...なんて\nお前には無理かw",
                            style: GoogleFonts.mPlus1p(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadClearedDates(); // 月が変わったらクリア状況再取得
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: GoogleFonts.mPlus1p(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.orange),
                        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.orange),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: const TextStyle(color: Colors.white),
                        weekendTextStyle: const TextStyle(color: Colors.orangeAccent),
                        outsideTextStyle: TextStyle(color: Colors.grey[700]),
                        todayDecoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        // クリア済みの日付にマーカーを表示
                        markerBuilder: (context, date, events) {
                          final dateId = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                          if (_clearedDates.contains(dateId)) {
                            return Positioned(
                              bottom: 1,
                              right: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green, // クリア時は緑
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                width: 16,
                                height: 16,
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            );
                          }
                          return null;
                        },
                        // 無効な日付（未来）のスタイル
                        disabledBuilder: (context, date, _) {
                           return Center(
                             child: Text(
                               '${date.day}',
                               style: TextStyle(color: Colors.grey[800]),
                             ),
                           );
                        },
                      ),
                      enabledDayPredicate: (date) {
                        // 未来の日付は無効
                        return !date.isAfter(DateTime.now());
                      },
                    ),
                  ),
                ),
                
                // スタートボタン
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'START MISSION',
                      style: GoogleFonts.pressStart2p(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
