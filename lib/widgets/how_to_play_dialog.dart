import 'package:flutter/material.dart';

class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.cyanAccent : Colors.indigo,
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: isDark ? Colors.redAccent : Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '遊び方（笑）',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Stack(
          children: [
            // 背景画像 (薄く)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/cookie_mascot.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // コンテンツ
            const SingleChildScrollView(
              child: HowToPlayContent(),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '分かったよ...',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HowToPlayContent extends StatelessWidget {
  const HowToPlayContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          '基本ルール',
          '縦・横・太枠の中に1〜9の数字を一つずつ入れる。\nたったこれだけ。\n...まさか、これすら理解できないわけじゃないよな？\n空欄を埋めるだけの簡単なお仕事ですw',
          Icons.grid_4x4,
        ),
        _buildSection(
          context,
          'ゲームオーバー条件',
          '3回間違えたら即終了。\n「間違えました」で済むのは学校までだぞ？\n甘えは一切許さない。\n集中力ないなら帰って寝てなw',
          Icons.dangerous,
        ),
        _buildSection(
          context,
          '便利機能（雑魚用）',
          '■ オートメモ\n空いてるマスに候補の数字を全部書いてやるよ。\n自分で考えるのを放棄した思考停止人間にピッタリだなw\n\n■ クイックモード\n数字を選んでからマスをタップする高速連続入力モード。\n調子に乗ってミス連発して発狂すんなよ？\nお前の指さばき、見せてもらおうかw',
          Icons.auto_awesome,
        ),
        _buildSection(
          context,
          'ヒント',
          '降参ボタン...あ、ヒント機能か。\nどうしても分からない時の情けない救済措置。\n使うたびに俺が全力で煽ってやるから、\n涙目になりながら感謝して使えよ？',
          Icons.lightbulb_outline,
        ),
        _buildSection(
          context,
          'デイリーミッションとは？',
          '毎日一つ、俺様が厳選した激辛問題を食わせてやるよ。\n当日中にクリアすればポイント10倍だ。太っ腹だろ？\n過ぎた日付の問題？ ああ、やりたきゃやれば？\nポイントは通常通りだけどな。\nただの暇つぶしがお望みなら、好きにシケたクッキーでも食ってなw',
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String description, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.cyanAccent.withOpacity(0.3) : Colors.indigo.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.cyanAccent : Colors.indigo).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.redAccent.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.redAccent : Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.redAccent : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.6,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
