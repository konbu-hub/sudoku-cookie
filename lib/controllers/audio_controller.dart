import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用


class AudioController with WidgetsBindingObserver {
  static final AudioController _instance = AudioController._internal();
  factory AudioController() => _instance;
  
  AudioController._internal() {
    print('DEBUG: AudioController Instance Created');
  }

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // 音量設定
  // 音量設定
  double _sfxVolume = 1.0;
  double _bgmVolume = 0.5;
  
  // ミュート用状態
  bool _isMuted = false;
  double _previousSfxVolume = 1.0;
  double _previousBgmVolume = 0.5;

  // Getters
  double get sfxVolume => _sfxVolume;
  double get bgmVolume => _bgmVolume;
  bool get isMuted => _isMuted;

  Future<void> init() async {
    await _loadSettings();
    
    // SFX Player: 低遅延 + 一時的なフォーカス（BGMを邪魔しない）
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    try {
      await _sfxPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // BGMを小さくするだけ
        ),
      ));
      print('DEBUG: SFX AudioContext configured (gainTransientMayDuck)');
    } catch (e) {
      print('Error setting SFX AudioContext: $e');
    }

    // BGM Player: メディアプレイヤー + 永続的なフォーカス
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    try {
      await _bgmPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain, // BGMは常にフォーカスを保持
        ),
      ));
      print('DEBUG: BGM AudioContext configured (gain)');
    } catch (e) {
      print('Error setting BGM AudioContext: $e');
    }

    // BGM状態監視: 予期せず停止した場合は自動再開
    _bgmPlayer.onPlayerStateChanged.listen((state) {
      print('DEBUG: BGM Player State: $state');
      if (state == PlayerState.stopped && _currentBgm != null) {
        print('DEBUG: BGM unexpectedly stopped. Auto-resuming...');
        Future.delayed(const Duration(milliseconds: 100), () {
          playBgm(fileName: _currentBgm!);
        });
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('DEBUG: [Lifecycle] $state');
    if (state == AppLifecycleState.resumed && _currentBgm != null) {
      print('DEBUG: [Lifecycle] App Resumed - Ensuring BGM is playing');
      if (_bgmPlayer.state != PlayerState.playing) {
        _bgmPlayer.resume();
      }
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.hidden) {
      print('DEBUG: [Lifecycle] App Background - Pausing BGM');
      _bgmPlayer.pause();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 1.0;
    _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.5;
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', volume);
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume;
    await _bgmPlayer.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', volume);
  }

  /// ミュート切り替え
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    
    if (_isMuted) {
      // ミュートにする: 現在の音量を保存して0にする
      _previousSfxVolume = _sfxVolume > 0 ? _sfxVolume : 1.0;
      _previousBgmVolume = _bgmVolume > 0 ? _bgmVolume : 0.5;
      
      await setSfxVolume(0);
      await setBgmVolume(0);
    } else {
      // ミュート解除: 保存した音量に戻す
      await setSfxVolume(_previousSfxVolume);
      await setBgmVolume(_previousBgmVolume);
    }
    // _isMutedフラグはsetVolumeでfalseにされる可能性があるので、明示的に管理が必要だが
    // setVolume呼び出し内で_isMuted = falseにするとループや意図しない解除が起きるかも
    // ここではシンプルに「setVolume(0)しても_isMutedはtrueのまま」にしたいが、
    // 実装上はvolume=0 == visually mutedなので、_isMutedフラグはUI表示用として使う。
  }


  // SFX再生
  Future<void> playSelect() async => _playSfx('Click.mp3');
  Future<void> playReturn() async => _playSfx('Click.mp3');
  Future<void> playInput() async => _playSfx('Click.mp3'); 
  Future<void> playSuccess() async => _playSfx('OK.mp3');
  Future<void> playError() async => _playSfx('miss.mp3');
  Future<void> playClear() async => _playSfx('Clear.mp3');
  Future<void> playGameStart() async => _playSfx('GameStart.mp3');
  Future<void> playGameOver() async => _playSfx('miss.mp3');
  Future<void> playMascot() async => _playSfx('chara.mp3'); 
  Future<void> playSubClear() async => _playSfx('subclear.mp3'); // 数字完成時 

  // BGM再生メソッド
  Future<void> playDailyBgm() async => playBgm(fileName: 'daily.mp3');
  Future<void> playTitleBgm() async => playBgm(fileName: 'Title.mp3');
  Future<void> playMainBgm() async => playBgm(fileName: 'main_bgm.mp3');

  // 振動フィードバック
  Future<void> vibrateGameOver() async {
    try {
      await HapticFeedback.mediumImpact(); // 中程度の振動
    } catch (e) {
      print('Vibration Error: $e');
    }
  }

  Future<void> vibrateMascotExplosion() async {
    try {
      await HapticFeedback.vibrate(); // 長めの振動
    } catch (e) {
      print('Vibration Error: $e');
    }
  } 

  Future<void> _playSfx(String fileName) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      print('Audio Error ($fileName): $e');
    }
  }

  // BGM制御
  Future<void> playBgm({String fileName = 'main_bgm.mp3'}) async {
    print('DEBUG: [playBgm] Req: $fileName, Current: $_currentBgm, State: ${_bgmPlayer.state}');
    try {
      // 同じ曲が再生中なら何もしない
      if (_currentBgm == fileName && _bgmPlayer.state == PlayerState.playing) {
        return;
      }

      // 同じ曲だが一時停止中なら再開
      if (_currentBgm == fileName) {
        if (_bgmPlayer.state != PlayerState.playing) {
          await _bgmPlayer.resume();
          await _fadeIn(); // 再開後にフェードイン
          return;
        }
      } 
      
      // 曲の切り替え
      if (_currentBgm != null && _bgmPlayer.state == PlayerState.playing) {
        await _fadeOut(); // 現在の曲をフェードアウト
        await _bgmPlayer.stop();
      }

      _currentBgm = fileName;
      
      // 音量を0にしてから再生開始し、フェードイン
      await _bgmPlayer.setVolume(0);
      await _bgmPlayer.play(AssetSource('audio/$fileName'));
      await _fadeIn();

      print('DEBUG: [playBgm] play() called for $fileName with fade-in.');
    } catch (e) {
      print('BGM Error ($fileName): $e');
    }
  }

  Future<void> _fadeOut() async {
    // 0.5秒かけて音量を下げる
    double startVolume = _bgmVolume;
    int steps = 10;
    int durationMs = 500;
    int stepTime = durationMs ~/ steps;

    for (int i = 1; i <= steps; i++) {
        double vol = startVolume * (1 - i / steps);
        if (vol < 0) vol = 0;
        await _bgmPlayer.setVolume(vol);
        await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  Future<void> _fadeIn() async {
    // 0.5秒かけて音量を上げる
    double targetVolume = _bgmVolume;
    int steps = 10;
    int durationMs = 500;
    int stepTime = durationMs ~/ steps;

    for (int i = 1; i <= steps; i++) {
        double vol = targetVolume * (i / steps);
        if (vol > 1.0) vol = 1.0;
        await _bgmPlayer.setVolume(vol);
        await Future.delayed(Duration(milliseconds: stepTime));
    }
    // 最終的に設定音量に確実にする
    await _bgmPlayer.setVolume(_bgmVolume);
  }

  /// タイトルBGMの生存確認と強制再生 (シーン！対策)
  Future<void> ensureTitleBgm() async {
    if (_currentBgm == 'Title.mp3' && _bgmPlayer.state == PlayerState.playing) {
      print('DEBUG: [ensureTitleBgm] Already playing Title.mp3');
      return;
    }
    print('DEBUG: [ensureTitleBgm] Title.mp3 is not playing. Forcing recovery.');
    await playBgm(fileName: 'Title.mp3');
  }

  String? _currentBgm;

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _currentBgm = null;
  }
}
