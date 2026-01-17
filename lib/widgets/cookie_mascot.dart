import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../controllers/audio_controller.dart';
import '../data/mascot_messages.dart';

class CookieMascot extends StatefulWidget {
  const CookieMascot({super.key});

  @override
  State<CookieMascot> createState() => _CookieMascotState();
}

class _CookieMascotState extends State<CookieMascot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _idleTimer;

  String _displayMessage = "さっさと始めろよ...";
  int _lastErrors = 0;
  int _lastHints = 0;
  int _lastMascotClicks = 0;
  int _lastCorrectCount = 0; // 連続正解数を追跡
  bool _wasClear = false;
  bool _isExploding = false;

  // 進捗率のマイルストーン管理
  final Set<int> _reachedMilestones = {};

  DateTime _lastMessageTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    _resetIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 3), _handleIdle); // 3秒ごとに更新
  }

  void _handleIdle() {
    if (!mounted) return;
    final idleMessages = MascotMessages.allMessages;
    _showMessage((idleMessages..shuffle()).first);
    _idleTimer = Timer(const Duration(seconds: 3), _handleIdle); // 3秒ごとに更新
  }

  void _showMessage(String msg) {
    if (_displayMessage == msg) return;
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _displayMessage = msg;
        _lastMessageTime = DateTime.now();
      });
      _resetIdleTimer();
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        _checkGameState(gameProvider);
        
        // 画面の揺れ
        Offset shakeOffset = Offset.zero;
        if (_isExploding) {
          double shakeAmount = 10.0;
          shakeOffset = Offset(
            (DateTime.now().millisecond % 3 - 1) * shakeAmount,
            (DateTime.now().microsecond % 3 - 1) * shakeAmount,
          );
        }

        // 煽りモード判定
        final tauntMessage = gameProvider.tauntMessage;
        final isTaunting = tauntMessage != null;

        // 1. 通常時の位置（左上）
        // 2. 煽り時の位置（画面中央）
        // Note: Stackの中でPositionedを使うため、位置計算は各ウィジェットで行う
        
        final size = MediaQuery.of(context).size;
        
        // --- マスコットの位置とスケール ---
        double mascotTop = 10 + shakeOffset.dy;
        double mascotLeft = 10 + shakeOffset.dx;
        double mascotScale = 1.0;

        if (isTaunting) {
          mascotTop = size.height / 2 - 100; // 画面中央やや上
          mascotLeft = size.width / 2 - 50;  // 画面中央
          mascotScale = 3.5;                 // 巨大化
        }

        // --- 吹き出しの位置と透明度 ---
        // 通常時: マスコットの右 (Top: 20, Left: 110)
        // 煽り時: マスコットの上 (Top: mascotTop - 100, Center)
        double bubbleTop = 20 + shakeOffset.dy;
        double bubbleLeft = 85 + shakeOffset.dx;
        // 逃走中（オーバーレイ表示中）は吹き出しを消す
        double bubbleOpacity = gameProvider.isRunningAway ? 0.0 : 1.0;

        if (isTaunting) {
          bubbleTop = size.height / 2 - 250; 
          bubbleLeft = (size.width - 280) / 2; // 中央寄せ (幅280想定)
        }

        return Stack(
          children: [
            // 全画面フラッシュ用の赤いレイヤー
            if (_isExploding)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withOpacity(0.3 + (DateTime.now().millisecond % 500 / 1000)),
                ),
              ),
            
            // --- マスコット (画像) ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: mascotTop,
              left: mascotLeft,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                scale: mascotScale,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: () {
                      if (isTaunting) return;
                      gameProvider.handleMascotTap();
                      AudioController().playMascot();
                      _handleMascotTapSideEffects(gameProvider);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none, // 内容がはみ出ても表示する
                      children: [
                        ScaleTransition(
                          scale: _isExploding ? _explosionScale : const AlwaysStoppedAnimation(1.0),
                          child: ColorFiltered(
                            colorFilter: _isExploding 
                                ? const ColorFilter.mode(Colors.red, BlendMode.modulate)
                                : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                            child: Image.asset(
                              gameProvider.isGameClear 
                                  ? 'assets/images/win.png' 
                                  : 'assets/images/cookie_mascot_evil.png',
                              width: 90,
                              height: 90,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 吹き出し (テキスト) ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              top: bubbleTop,
              left: bubbleLeft,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: bubbleOpacity,
                child: Container(
                  width: isTaunting ? 280 : 200, // 煽り時は少し幅広に
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTaunting ? Colors.red[900]?.withOpacity(0.95) : Colors.grey[900]?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isTaunting ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isTaunting ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: isTaunting ? 15 : 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                    border: isTaunting ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                        isTaunting ? tauntMessage : _displayMessage,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTaunting ? 22 : 14, // 煽り時は大きく
                          height: 1.2,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                        textAlign: isTaunting ? TextAlign.center : TextAlign.left,
                      ),
                     ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMascotTapSideEffects(GameProvider gameProvider) {
    final clicks = gameProvider.gameState.mascotClicks;
    if (clicks >= 10) {
      _triggerExplosion();
    } else if (clicks == 9) {
      _showMessage("......殺すぞ。");
    } else if (clicks == 8) {
      _showMessage("マジでやめろっつってんだろ。");
    } else if (clicks == 7) {
      _showMessage("おい、指切り落とすぞ？");
    } else if (clicks == 6) {
      _showMessage("まだやんのか？\n後悔するぞ。");
    } else if (clicks == 5) {
      _showMessage("調子乗んなよ...\nヒント禁止、即死モード、\nスコアも無効だ。覚悟しろ。");
    } else {
      final randomMessages = [
        '触んなよ、手が汚れるだろ。',
        '数独に集中しろ。菓子なら他を当たれ。',
        '…なんだ、腹が減ってるのか？',
        '俺の顔に何かついてるか。',
        'お前のその無駄な動き、嫌いじゃないぜw',
        'イキってんじゃねーよw',
        '早くしろ、俺の焼き加減が変わっちまう。',
        '次はどこを埋めるんだ？',
        '…ふん、案外やるじゃねえか。',
      ];
      _showMessage(randomMessages[DateTime.now().millisecond % randomMessages.length]);
    }
  }

  void _checkGameState(GameProvider provider) {
    // ゲームクリア時は勝利メッセージで固定し、他の更新をブロック
    if (provider.isGameClear) {
      String winMessage = "ぐぬぬ...くやしい！！！\n次は覚えてろよ！";
      
      // まだ勝利メッセージを表示していない場合のみ更新
      if (_displayMessage != winMessage) {
         _showMessage(winMessage);
         _wasClear = true;
      }
      return; 
    }
    
    // リセット（再プレイ時など）
    if (!provider.isGameClear && _wasClear) {
      _wasClear = false;
    }

    if (provider.gameState.isGameOver) {
      if (provider.gameState.mascotClicks < 10) {
        final gameOverMessages = [
          // 既存
          "ほら見ろ、雑魚がw\n出直してきな！",
          "やっぱりな〜\n最初から無理だと思ってたw",
          "3回ミスって終了〜！\nざっこw",
          "修行失敗！\nまぁ予想通りだけどな",
          "はい、お疲れ様〜\n次も失敗するんだろうけどw",
          // 新規追加
          "お疲れ〜\n無駄な時間だったねw",
          "また負けたの？\n学習しないねw",
          "3回で終了とか\n早すぎw",
          "もう終わり？\n物足りないなw",
          "弱すぎて草",
          "これが実力か\n情けないw",
          "次は頑張れよ\n無理だろうけどw",
          "才能ないって\n証明されたねw",
          "諦めが早いね\nいいことだw",
          "ゲームオーバー！\nざまぁw",
          "敗北者じゃけぇw",
          "雑魚確定w",
          "もう来なくていいよw",
          "時間の無駄だったねw",
          "お前には無理だったw",
          "レベル低すぎw",
          "センスゼロw",
          "向いてないって\n分かった？w",
          "別のゲーム探せw",
          "もう帰れw",
          "二度と来るなw",
          "恥ずかしくないの？w",
          "これが現実だよw",
          "実力不足w",
          "努力が足りないw",
          "才能が足りないw",
          "全てが足りないw",
          "完全敗北w",
          "惨敗じゃんw",
        ];
        _showMessage((gameOverMessages..shuffle()).first);
      }
      return;
    }

    if (provider.gameState.errors > _lastErrors) {
      final errorMessages = [
        // 既存
        "ププッ、間違えてやんのw",
        "えっ、マジで？\n笑えるんだけどw",
        "才能ないんじゃない？",
        "地味に痛いなソレw",
        "おっと〜！\nまた間違えたのかよw",
        "あちゃ〜\nそれは違うって分かんない？",
        "うわぁ...残念すぎるw",
        "ドンマイ？\nいや、ダメだろそれw",
        "焦りすぎw\n落ち着けよ雑魚",
        "よく考えろって\n脳みそ使ってる？",
        "ぷぷっ！そこ違うよ〜？",
        "え、まじで？\nそこ入れちゃう？",
        "やっぱりダメだったね〜",
        "もう諦めたら？",
        "その頭で解けると思った？",
        "小学生でも分かるぞ？",
        "目ぇ悪いの？\n数字見えてる？",
        "センスないわ〜",
        "もっと真剣にやれよw",
        "適当すぎだろw",
        // 新規大量追加
        "間違い確定w",
        "ミス乙w",
        "やらかしたねw",
        "ダメダメw",
        "全然ダメw",
        "論外w",
        "話にならんw",
        "レベル低いw",
        "下手くそw",
        "ヘタレw",
        "弱すぎw",
        "雑魚確w",
        "センスゼロw",
        "才能皆無w",
        "向いてないw",
        "諦めろw",
        "無理無理w",
        "できないw",
        "ムリゲーw",
        "詰んでるw",
        "オワコンw",
        "終わったw",
        "ダサw",
        "恥ずかしw",
        "情けないw",
        "残念w",
        "悲しいw",
        "泣けるw",
        "笑えるw",
        "草生えるw",
        "大草原w",
      ];
      _showMessage((errorMessages..shuffle()).first);
      _lastErrors = provider.gameState.errors;
      return;
    }

    if (provider.gameState.hintsUsed > _lastHints) {
      final hintMessages = [
        "甘えるなよ...",
        "知恵借りて楽しいか？",
        "俺様の時間を無駄にすんな",
        "ヒント使っちゃうの？\nだっせーw",
        "困った時はヒント！\nって、甘えすぎだろw",
        "ヒントに頼りすぎ\n自分で考えろよ",
        "ここでヒント使うとか\nセンスねーなw",
        "まぁ使えばいいけど\n雑魚確定だなw",
      ];
      _showMessage((hintMessages..shuffle()).first);
      _lastHints = provider.gameState.hintsUsed;
      return;
    }

    // 正解入力時の反応（悩しがるコメント）
    final currentProgress = provider.progressPercentage;
    if (currentProgress > _lastCorrectCount) {
      final successMessages = [
        "ちっ...正解かよ",
        "くそっ...まぐれだろ",
        "調子乗ってんじゃねぇよ",
        "むっ...次は間違えろよ",
        "くっ...運がいいな",
        "ちっ、まじかよ...",
        "くそったれ！",
        "むかつく...",
        "ちっ、うぜぇ...",
        "くっ...悩しいな",
        "まぐれだろうが！",
        "次は絶対間違えろよ！",
        "ちっ...認めないぞ",
        "くそっ...悩しい",
        "むかつくなぁ...",
        "調子乗るなよ！",
        "くっ...まだ終わってないぞ",
        "ちっ...次はそうはいかないぞ",
        "むっ...悩しいけど認める",
        "くそっ...やるじゃん",
      ];
      // 3回に1回は反応する（頻度調整）
      if ((currentProgress - _lastCorrectCount) >= 3 || currentProgress % 10 == 0) {
        _showMessage((successMessages..shuffle()).first);
      }
      _lastCorrectCount = currentProgress;
    }



    int progress = provider.progressPercentage;
    if (progress >= 25 && !_reachedMilestones.contains(25)) {
      final progress25Messages = [
        "お、意外とやるじゃん\nまぐれだろうけど",
        "順調？\nここからが地獄だけどなw",
        "その調子で頑張れよ\n無理だろうけどw",
      ];
      _showMessage((progress25Messages..shuffle()).first);
      _reachedMilestones.add(25);
    } else if (progress >= 50 && !_reachedMilestones.contains(50)) {
       // ... other milestones ...
      _reachedMilestones.add(50);
    } else if (progress >= 75 && !_reachedMilestones.contains(75)) {
      _reachedMilestones.add(75);
    } else if (progress >= 90 && !_reachedMilestones.contains(90)) {
      _reachedMilestones.add(90);
    }

    if (provider.gameState.mascotClicks >= 5 && _lastMascotClicks < 5) {
      _showMessage("おい...ふざけんなよ。\nヒント禁止、即死モード、\nスコアも無効だ。");
      _lastMascotClicks = provider.gameState.mascotClicks;
      return;
    }
    
    if (provider.gameState.mascotClicks >= 10 && _lastMascotClicks < 10) {
      _triggerExplosion();
      _lastMascotClicks = provider.gameState.mascotClicks;
      return;
    }
  }

  void _triggerExplosion() {
    if (_isExploding) return;
    setState(() {
      _isExploding = true;
      _displayMessage = "消えろ雑魚がぁぁ！！！";
    });
    
    _controller.duration = const Duration(milliseconds: 100);
    _controller.repeat(reverse: true);
    
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isExploding = false;
        });
        _controller.stop();
        _controller.duration = const Duration(milliseconds: 500);
        _controller.forward();
      }
    });
  }

  Animation<double> get _explosionScale => TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.5, end: 4.0), weight: 50),
  ]).animate(_controller);
}
