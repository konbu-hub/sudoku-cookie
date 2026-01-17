import 'package:flutter/material.dart';
import '../widgets/blended_mascot.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../models/sudoku_puzzle.dart';
import '../controllers/audio_controller.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import '../repositories/ranking_repository.dart';
import 'settings_screen.dart';
import '../widgets/how_to_play_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';



/// タイトル画面
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  @override
  void initState() {
    super.initState();
    // BGM再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController().playBgm(fileName: 'Title.mp3');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // クッキーキャラクター
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/cookie_evil.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: theme.colorScheme.surface,
                                child: Icon(
                                  Icons.cookie,
                                  size: 80,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // タイトル (Cyber Glitch Ver.)
                      Stack(
                        children: [
                          // 1. Cyan Layer (Left/Top Offset)
                          Transform.translate(
                            offset: const Offset(-1, -1),
                            child: Text(
                              'おしゃべりクッキーの\nSUDOKU',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.cyanAccent.withOpacity(0.5),
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .shake(duration: 2000.ms, hz: 0.5, offset: const Offset(-0.25, 0)) // さらに微細なズレ (0.5 -> 0.25)
                           .fadeIn(duration: 100.ms).then().fadeOut(duration: 100.ms, delay: 5000.ms),
                          
                          // 2. Magenta Layer (Right/Bottom Offset)
                          Transform.translate(
                            offset: const Offset(1, 1),
                            child: Text(
                              'おしゃべりクッキーの\nSUDOKU',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.purpleAccent.withOpacity(0.5),
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .shake(duration: 2000.ms, hz: 0.5, offset: const Offset(0.25, 0)) // さらに微細なズレ (0.5 -> 0.25)
                           .fadeIn(duration: 100.ms).then().fadeOut(duration: 100.ms, delay: 7000.ms),

                          // 3. Main Layer (Theme-aware)
                          Text(
                            'おしゃべりクッキーの\nSUDOKU',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: 32, 
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.indigo.shade900 // ライトモード: 濃い青
                                  : Colors.white, // ダークモード: 白
                              shadows: [
                                BoxShadow(
                                  color: Theme.of(context).brightness == Brightness.light
                                      ? Colors.indigo.withOpacity(0.3)
                                      : Colors.blueAccent.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ), // メインの揺れは削除（どっしり構える）
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // ウェルカムメッセージ
                      Consumer<GameProvider>(
                        builder: (context, gameProvider, child) {
                          final username = gameProvider.gameState.username.isEmpty 
                              ? 'プレイヤー' 
                              : gameProvider.gameState.username;
                          return Text(
                            'ようこそ、$username さん',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // メニューボタン
                      _MenuButton(
                        label: '新しく始める',
                        icon: Icons.play_arrow,
                        isPrimary: true,
                        onPressed: () => _showDifficultyDialog(context),
                      ),
                      


                      const SizedBox(height: 20), // スペース確保
                    ],
                  ),
                ),
              ),
              
              // 会社クレジット
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/konbu.tokyo2-touka.png',
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '© KONBU.TOKYO ENTERPRISE',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.indigo.shade900.withOpacity(0.5)
                              : Colors.white.withOpacity(0.5),
                          fontSize: 10, // Small and subtle
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // バージョン表記 (最下部右)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Ver 1.2.6',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                              ? Colors.indigo.shade900.withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              

            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 難易度選択ダイアログを表示
  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // キャラクターと煽りコメント
              Row(
                children: [
                  const BlendedMascot(
                    assetPath: 'assets/images/cookie_mascot_evil.png',
                    width: 70,
                    height: 70,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'おい、早く選べや！',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          'お前にクリアできるかな？',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              // 難易度ボタン
              ...Difficulty.values.map((difficulty) {
                // 難易度ごとの色とアイコンを設定
                Color startColor;
                Color endColor;
                IconData icon;
                
                switch (difficulty) {
                  case Difficulty.easy:
                    startColor = Colors.green.shade300;
                    endColor = Colors.green.shade600;
                    icon = Icons.sentiment_satisfied;
                    break;
                  case Difficulty.medium:
                    startColor = Colors.blue.shade300;
                    endColor = Colors.blue.shade600;
                    icon = Icons.sentiment_neutral;
                    break;
                  case Difficulty.hard:
                    startColor = Colors.orange.shade300;
                    endColor = Colors.orange.shade600;
                    icon = Icons.sentiment_dissatisfied;
                    break;
                  case Difficulty.expert:
                    startColor = Colors.red.shade300;
                    endColor = Colors.red.shade600;
                    icon = Icons.local_fire_department;
                    break;
                  case Difficulty.extreme:
                    startColor = Colors.purple.shade300;
                    endColor = Colors.purple.shade900;
                    icon = Icons.bolt;
                    break;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [startColor, endColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: endColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          AudioController().playGameStart();
                          Navigator.of(context).pop();
                          _startGame(context, difficulty);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  difficulty.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  AudioController().playReturn();
                  
                  // 乱数でメッセージを決定
                  final preGameRunAwayMessages = [
                    "おい、早く選べや！\nお前にクリアできるかな？",
                    "まだ始まってもねぇぞ...？\nビビり散らかしてんじゃねーよw",
                    "おいおい、逃げるのか？\nまさか数字が怖いのか？w",
                    "指が震えてるぞ？w\n正直に言えよ、怖いんだろ？",
                    "逃げる練習か？\n人生でもそうやって逃げるのかw",
                    "まだ何もしてねぇのにw\n想像だけでチビったか？",
                    "期待外れだな...\n戦う前から負ける奴w",
                    "帰るボタンはここじゃねぇぞ\n...あ、逃げるボタンかw",
                    "お前の勇気、軽っw\n空気より軽いんじゃね？",
                    "本気で言ってる？\n画面の前で土下座してから押せよw",
                  ];
                  final randomMessage = preGameRunAwayMessages[DateTime.now().millisecondsSinceEpoch % preGameRunAwayMessages.length];

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('本気で逃げるのか？'),
                      content: Row(
                        children: [
                          Image.asset('assets/images/cookie_mascot_evil.png', width: 50, height: 50),
                          const SizedBox(width: 12),
                          Expanded(child: Text(randomMessage)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('やる'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AudioController().playMascot();
                            RankingRepository().incrementRunAwayCount();
                            Navigator.pop(context); // Confirm Dialog
                            Navigator.pop(context); // Difficulty Dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('逃げた回数が記録されました（笑）'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('逃げる'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('ビビってやめる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ゲームを開始
  void _startGame(BuildContext context, Difficulty difficulty) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.startNewGame(difficulty, 'PLAYER'); 
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );

    // ゲームから戻ってきたらタイトルBGMを再開
    if (context.mounted) {
      // 少し待ってからBGMを切り替え（SFXとの競合回避）
      Future.delayed(const Duration(milliseconds: 300), () {
        AudioController().playBgm(fileName: 'Title.mp3');
      });
    }
      // 逃げて帰ってきた場合の煽りメッセージ
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('逃げた回数が記録されました（笑）'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
  }
}

/// メニューボタンウィジェット
class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          AudioController().playSelect();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isPrimary
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
