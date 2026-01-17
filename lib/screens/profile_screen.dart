import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
import '../repositories/ranking_repository.dart';
import '../controllers/audio_controller.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _hasUsernameChanged = false;
  bool _isSaving = false;
  String _originalUsername = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController().ensureTitleBgm();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // プロバイダーから最新のユーザー名を取得し、
    // まだ編集されていない（もしくは初期化時）であればControllerに反映する
    final gameProvider = Provider.of<GameProvider>(context);
    final currentProviderName = gameProvider.gameState.username;
    
    if (_originalUsername != currentProviderName && !_hasUsernameChanged) {
      _originalUsername = currentProviderName;
      _nameController.text = currentProviderName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    // UI反映の演出として少し待つ
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final newUsername = _nameController.text;
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // GameProvider & Prefs更新
      await gameProvider.updateUsername(newUsername);
      
      // ランキングデータのユーザー名も更新
      final user = AuthService().currentUser;
      if (user != null) {
        await RankingRepository().updateUsername(user.uid, newUsername);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final localId = prefs.getString('local_user_id') ?? '';
        if (localId.isNotEmpty) {
          await RankingRepository().updateUsername(localId, newUsername);
        }
      }
      
      if (mounted) {
        setState(() {
          _originalUsername = newUsername;
          _hasUsernameChanged = false;
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
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
        title: const Text('プロフィール'),
      ),
      body: AbsorbPointer( // 保存中は操作無効
        absorbing: _isSaving,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('アカウント'),
            _buildAccountSection(),
            const SizedBox(height: 32),

            _buildSectionTitle('プロフィール設定'),
            _buildProfileSection(),
          ],
        ),
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

  Widget _buildAccountSection() {
    final user = AuthService().currentUser;
    final isLoggedIn = user != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: isLoggedIn && user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: isLoggedIn && user.photoURL == null
                    ? const Icon(Icons.person)
                    : (isLoggedIn ? null : const Icon(Icons.person_off)),
              ),
              title: Text(isLoggedIn ? (user.displayName ?? 'Google User') : '未連携'),
              subtitle: Text(isLoggedIn ? 'Googleで連携済み' : 'ゲストとしてプレイ中'),
              trailing: isLoggedIn
                  ? OutlinedButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        // ログアウト時はPlayerに戻す
                        final gameProvider = Provider.of<GameProvider>(context, listen: false);
                        await gameProvider.updateUsername('Player');
                        if (mounted) {
                          setState(() {
                             _originalUsername = 'Player';
                             _nameController.text = 'Player';
                             _hasUsernameChanged = false;
                          });
                        }
                      },
                      child: const Text('ログアウト'),
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('連携する'),
                      onPressed: () async {
                        try {
                          final user = await AuthService().linkWithGoogle();
                          if (user != null) {
                            // ユーザー名は変更しない(手動入力を優先)
                            // 認証のみ完了
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Googleアカウントと連携しました（データ引き継ぎ完了）'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('Link Logic Error: $e');
                          String errorMessage = '連携に失敗しました: ';
                          
                          // エラーメッセージの改善
                          if (e.toString().contains('credential-already-in-use')) {
                              errorMessage = 'このGoogleアカウントは既に他のデータと紐付いています。\n連携するには、一度ログアウトしてGoogleでログインし直してください（現在のゲストデータは引き継げません）。';
                          } else {
                              errorMessage += e.toString();
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
            if (!isLoggedIn)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '※Google連携すると、機種変更時もデータを引き継げます',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSaving, // 保存中は無効化
              decoration: InputDecoration(
                labelText: 'ユーザー名',
                hintText: 'ランキングに表示される名前',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                filled: _isSaving,
                fillColor: _isSaving ? Colors.grey[200] : null,
              ),
              onChanged: (value) {
                setState(() {
                  _hasUsernameChanged = value != _originalUsername;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasUsernameChanged && !_isSaving) ? _handleSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUsernameChanged ? null : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('変更を確定'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '※全国ランキングにはこの名前で登録されます',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
