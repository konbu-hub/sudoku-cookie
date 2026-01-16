import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../controllers/audio_controller.dart';
import '../repositories/ranking_repository.dart';
import '../services/auth_service.dart';


class SettingsScreen extends StatefulWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioController _audioController = AudioController();

  @override
  void initState() {
    super.initState();
    // BGMの生存確認
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController().ensureTitleBgm();
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('サウンド'),
          _buildAudioSection(),
          const SizedBox(height: 32),
          
          _buildSectionTitle('表示'),
          _buildDisplaySection(),
          const SizedBox(height: 32),
          
          _buildSectionTitle('ゲームプレイ'),
          _buildGameplaySection(),
          const SizedBox(height: 32),
          
          _buildSectionTitle('データ'),
          _buildDataSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );

  }

  Widget _buildAudioSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('すべてミュート'),
              value: _audioController.isMuted,
              onChanged: (val) {
                setState(() {
                  _audioController.toggleMute();
                });
              },
              secondary: Icon(
                _audioController.isMuted ? Icons.volume_off : Icons.volume_up,
                color: _audioController.isMuted ? Colors.red : null,
              ),
            ),
            const Divider(),
            _buildVolumeSlider(
              label: '効果音 (SE)',
              value: _audioController.sfxVolume,
              onChanged: (val) {
                setState(() {
                  _audioController.setSfxVolume(val);
                });
                // プレビュー再生
                if (val > 0) _audioController.playInput();
              },
            ),
            const Divider(),
            _buildVolumeSlider(
              label: 'BGM',
              value: _audioController.bgmVolume,
              onChanged: (val) {
                setState(() {
                  _audioController.setBgmVolume(val);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 5,
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('${(value * 100).toInt()}%', textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('プレイ履歴を削除'),
        subtitle: const Text('端末内のスコアデータが全て消去されます'),
        onTap: () => _showDeleteConfirmDialog(),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('【重要】データの完全削除'),
        content: const Text(
          '端末内のプレイ履歴だけでなく、\n'
          '**オンラインランキングの記録も全て削除**されます。\n\n'
          'この操作は絶対に取り消せません。\n'
          'これまでのクッキーとの思い出が全て消えてしまいますが、\n'
          '本当によろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 削除処理
              await RankingRepository().clearLocalHistory();
              await RankingRepository().clearRemoteData(); // オンラインデータも削除
              
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('全データを削除しました（クッキー「バイバイ...」）')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }



  Widget _buildDisplaySection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '表示設定',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ダークモード'),
                  subtitle: const Text('目に優しい暗いテーマ'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  secondary: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameplaySection() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'デフォルト設定',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ゲーム開始時の初期設定',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('オートメモ'),
                  subtitle: const Text('自動でメモを記入'),
                  value: gameProvider.gameState.isFastPencil,
                  onChanged: (value) {
                    gameProvider.toggleFastPencilMode();
                  },
                  secondary: Icon(
                    gameProvider.gameState.isFastPencil
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('クイックモード'),
                  subtitle: const Text('連続入力モード'),
                  value: gameProvider.gameState.isLightningMode,
                  onChanged: (value) {
                    gameProvider.toggleLightningMode();
                  },
                  secondary: Icon(
                    gameProvider.gameState.isLightningMode
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
