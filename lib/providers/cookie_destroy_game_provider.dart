import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/cookie_destroy_screen.dart';

class CookieDestroyGameProvider extends ChangeNotifier {
  List<FlyingCookie> _cookies = [];
  List<Offset> _swipePoints = [];
  List<SlicedCookie> _slicedCookies = [];
  int _score = 0;
  int _time = 0;
  Timer? _timer;
  Timer? _cookieSpawnTimer;
  Timer? _sliceAnimationTimer;
  bool _isGameClear = false;
  bool _isBossFight = false;
  int _bossHp = 20;
  int _bossHitCount = 0;
  bool _showDangerAlert = false;
  Size _screenSize = const Size(400, 800);

  List<FlyingCookie> get cookies => _cookies;
  List<Offset> get swipePoints => _swipePoints;
  List<SlicedCookie> get slicedCookies => _slicedCookies;
  int get score => _score;
  int get bossHp => _bossHp;
  int get bossHitCount => _bossHitCount;
  bool get isGameClear => _isGameClear;
  bool get isBossFight => _isBossFight;
  bool get showDangerAlert => _showDangerAlert;

  String get formattedTime {
    final minutes = _time ~/ 60;
    final seconds = _time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startGame() {
    _score = 0;
    _time = 0;
    _isGameClear = false;
    _isBossFight = false;
    _bossHp = 20;
    _bossHitCount = 0;
    _showDangerAlert = false;
    _cookies.clear();
    _swipePoints.clear();
    _slicedCookies.clear();

    // タイマー開始
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _time++;
      notifyListeners();
    });

    // 破裂エフェクトアニメーションタイマー
    _sliceAnimationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _slicedCookies = _slicedCookies.map((sliced) {
        return SlicedCookie(
          position: sliced.position,
          animationProgress: sliced.animationProgress + 0.02,
        );
      }).where((sliced) => sliced.animationProgress < 1.0).toList();
      notifyListeners();
    });

    // クッキー生成タイマー(大量出現)
    _cookieSpawnTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!_isBossFight && _score < 100) {
        _spawnCookie();
        // 四方八方から出現させるため、複数同時生成
        if (Random().nextBool()) {
          _spawnCookie();
        }
      }
    });

    // 物理更新ループ
    _startPhysicsLoop();
  }

  void _startPhysicsLoop() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isGameClear) {
        timer.cancel();
        return;
      }

      _updateCookies();
      notifyListeners();
    });
  }

  void _spawnCookie() {
    final random = Random();
    
    // 四方八方からランダムに出現
    double startX, startY, targetX, targetY;
    final side = random.nextInt(4);
    
    switch (side) {
      case 0: // 下から
        startX = random.nextDouble() * _screenSize.width;
        startY = _screenSize.height + 50;
        targetX = random.nextDouble() * _screenSize.width;
        targetY = -100.0;
        break;
      case 1: // 上から
        startX = random.nextDouble() * _screenSize.width;
        startY = -50.0;
        targetX = random.nextDouble() * _screenSize.width;
        targetY = _screenSize.height + 100;
        break;
      case 2: // 左から
        startX = -50.0;
        startY = random.nextDouble() * _screenSize.height;
        targetX = _screenSize.width + 100;
        targetY = random.nextDouble() * _screenSize.height;
        break;
      default: // 右から
        startX = _screenSize.width + 50;
        startY = random.nextDouble() * _screenSize.height;
        targetX = -100.0;
        targetY = random.nextDouble() * _screenSize.height;
    }

    final velocityX = (targetX - startX) / 120;
    final velocityY = (targetY - startY) / 120;

    _cookies.add(FlyingCookie(
      position: Offset(startX, startY),
      velocity: Offset(velocityX, velocityY),
    ));
  }

  void _spawnBoss() {
    _isBossFight = true;
    _showDangerAlert = true;
    _bossHitCount = 0;
    _cookieSpawnTimer?.cancel();

    // DANGERアラートを3秒後に消す
    Future.delayed(const Duration(seconds: 3), () {
      _showDangerAlert = false;
      notifyListeners();
    });

    final centerX = _screenSize.width / 2;
    final startY = -100.0;

    _cookies.add(FlyingCookie(
      position: Offset(centerX, startY),
      velocity: const Offset(0, 2),
      isBoss: true,
    ));

    notifyListeners();
  }

  void _updateCookies() {
    for (var cookie in _cookies) {
      if (cookie.isSliced) continue;

      cookie.position += cookie.velocity;

      // ボスは画面中央で上下に動く
      if (cookie.isBoss) {
        if (cookie.position.dy > _screenSize.height / 2) {
          cookie.velocity = const Offset(0, -2);
        } else if (cookie.position.dy < 100) {
          cookie.velocity = const Offset(0, 2);
        }
      }

      // 画面外に出たクッキーを削除
      if (cookie.position.dy < -100 || cookie.position.dy > _screenSize.height + 100) {
        if (!cookie.isBoss) {
          cookie.isSliced = true;
        }
      }
    }

    _cookies.removeWhere((cookie) => cookie.isSliced && !cookie.isBoss);
  }

  void handleSwipe(Offset point) {
    _swipePoints.add(point);

    // クッキーとの衝突判定
    for (var cookie in _cookies) {
      if (cookie.isSliced) continue;

      final distance = (point - cookie.position).distance;
      final radius = cookie.isBoss ? 50.0 : 30.0;

      if (distance < radius) {
        if (cookie.isBoss) {
          // ボスは20発で倒れる(isSlicedはまだtrueにしない)
          _bossHitCount++;
          print('Boss hit! Count: $_bossHitCount/20');
          
          if (_bossHitCount >= 20) {
            // 20回目でようやく倒れる
            cookie.isSliced = true;
            _slicedCookies.add(SlicedCookie(
              position: cookie.position,
              animationProgress: 0.0,
            ));
            _gameCleared();
          }
          // 20回未満の場合は何もしない(ボスは生き続ける)
        } else {
          // 通常のクッキーは1回で倒れる
          cookie.isSliced = true;
          _slicedCookies.add(SlicedCookie(
            position: cookie.position,
            animationProgress: 0.0,
          ));
          _score++;
          if (_score >= 100 && !_isBossFight) {
            _spawnBoss();
          }
        }
      }
    }

    notifyListeners();
  }

  void clearSwipe() {
    _swipePoints.clear();
    notifyListeners();
  }

  void _gameCleared() {
    _isGameClear = true;
    _timer?.cancel();
    _cookieSpawnTimer?.cancel();
    notifyListeners();

    // TODO: スコアをDBに保存
  }

  void setScreenSize(Size size) {
    _screenSize = size;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cookieSpawnTimer?.cancel();
    _sliceAnimationTimer?.cancel();
    super.dispose();
  }
}
