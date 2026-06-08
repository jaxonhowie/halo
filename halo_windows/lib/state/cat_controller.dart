import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cat_state.dart';

class BubbleData {
  final String text;
  final int color;
  final double x;
  double y;
  double opacity;
  final double startY;
  final double duration;
  double elapsed;
  bool isDone;

  BubbleData({
    required this.text,
    required this.color,
    required this.x,
    required this.startY,
    required this.duration,
  })  : y = startY,
        opacity = 1.0,
        elapsed = 0,
        isDone = false;
}

class HeartData {
  final String emoji;
  final double startX;
  final double startY;
  final double offsetX;
  double y;
  double opacity;
  double elapsed;
  final double delay;
  bool started;
  bool isDone;

  HeartData({
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.offsetX,
    required this.delay,
  })  : y = startY,
        opacity = 0,
        elapsed = 0,
        started = false,
        isDone = false;
}

class CatController extends ChangeNotifier {
  // Display constants
  static const double maxDisplayWidth = 144;
  static const double maxDisplayHeight = 148;
  static const double walkRange = 36.0;
  static const double walkSpeed = 30.0;
  static const double gravity = 400.0;
  static const double jumpInitialVelocity = 200.0;
  static const double windowSize = 208.0;

  // State
  CatState _state = CatState.idle;
  int _currentFrame = 0;
  double _frameTimer = 0;
  double _stateTimer = 0;
  double _direction = 1.0;
  bool _isJumping = false;
  double _jumpVelocity = 0;
  double _catX = windowSize / 2;
  final double _catBaseY = windowSize / 2;
  double _catY = windowSize / 2;
  final double _homeX = windowSize / 2;
  CatState? _pendingStateAfterWalk;

  // Bubbles and effects
  final List<BubbleData> _bubbles = [];
  final List<HeartData> _hearts = [];
  BubbleData? _meowBubble;

  // Getters
  CatState get state => _state;
  int get currentFrame => _currentFrame;
  double get direction => _direction;
  double get catX => _catX;
  double get catY => _catY;
  bool get isJumping => _isJumping;
  List<BubbleData> get bubbles => _bubbles;
  List<HeartData> get hearts => _hearts;

  // ignore: unused_field
  static const _transitionWeights = {
    CatState.idle: 0.35,
    CatState.walk: 0.35,
    CatState.sleep: 0.20,
    CatState.wantFish: 0.10,
  };

  void setState(CatState newState) {
    if (_state == newState) return;
    _state = newState;
    _currentFrame = 0;
    _frameTimer = 0;
    _stateTimer = 0;
    if (newState != CatState.walk) {
      _pendingStateAfterWalk = null;
    }
    _removeMeow();
    if (newState == CatState.walk) {
      // Random initial direction
      _direction = Random().nextBool() ? 1.0 : -1.0;
    }
    if (newState == CatState.jump) {
      _isJumping = true;
      _jumpVelocity = jumpInitialVelocity;
    }
    notifyListeners();
  }

  void update(double dt) {
    _frameTimer += dt;
    _stateTimer += dt;

    final config = stateConfigs[_state]!;
    if (_frameTimer >= 1.0 / config.fps) {
      _frameTimer = 0;
      _currentFrame = (_currentFrame + 1) % config.frameCount;
      notifyListeners();
    }

    // Jump physics (Flutter Y axis: down is positive)
    if (_isJumping) {
      _jumpVelocity -= gravity * dt;
      _catY -= _jumpVelocity * dt;
      if (_catY >= _catBaseY) {
        _catY = _catBaseY;
        _isJumping = false;
        _jumpVelocity = 0;
        setState(CatState.idle);
      }
      notifyListeners();
    }

    // Walk movement
    if (_state == CatState.walk) {
      _catX += walkSpeed * _direction * dt;
      const margin = 20.0;
      final maxX = min(windowSize - margin, _homeX + walkRange);
      final maxXVal = maxX;
      final minX = max(margin, _homeX - walkRange);
      final minXVal = minX;

      if (_pendingStateAfterWalk != null) {
        if ((_catX - _homeX).abs() <= 1.0) {
          _catX = _homeX;
          setState(_pendingStateAfterWalk ?? CatState.idle);
          _pendingStateAfterWalk = null;
        } else {
          _direction = _catX < _homeX ? 1.0 : -1.0;
        }
      } else if (_catX > maxXVal) {
        _catX = maxXVal;
        _direction = -1.0;
      } else if (_catX < minXVal) {
        _catX = minXVal;
        _direction = 1.0;
      }
      notifyListeners();
    }

    // State timer
    if (_stateTimer >= config.duration && !_isJumping) {
      if (_state == CatState.walk) {
        _beginWalkReturn();
      } else {
        _randomStateChange();
      }
    }

    // Update bubbles
    _bubbles.removeWhere((b) {
      b.elapsed += dt;
      b.y = b.startY - 20 * (b.elapsed / b.duration);
      b.opacity = (1.0 - b.elapsed / b.duration).clamp(0.0, 1.0);
      if (b.elapsed >= b.duration) {
        b.isDone = true;
        return true;
      }
      return false;
    });

    // Update hearts
    _hearts.removeWhere((h) {
      h.elapsed += dt;
      if (!h.started && h.elapsed >= h.delay) {
        h.started = true;
        h.opacity = 1.0;
      }
      if (h.started) {
        final heartElapsed = h.elapsed - h.delay;
        h.y = h.startY - 30 * (heartElapsed / 0.8);
        h.opacity = (1.0 - heartElapsed / 0.6).clamp(0.0, 1.0);
        if (heartElapsed >= 0.8) {
          h.isDone = true;
          return true;
        }
      }
      return false;
    });

    if (_bubbles.isNotEmpty || _hearts.isNotEmpty) {
      notifyListeners();
    }
  }

  void _beginWalkReturn() {
    if (_pendingStateAfterWalk != null) return;
    _pendingStateAfterWalk = Random().nextBool() ? CatState.idle : CatState.sleep;
    if ((_catX - _homeX).abs() <= 1.0) {
      _catX = _homeX;
      setState(_pendingStateAfterWalk ?? CatState.idle);
      _pendingStateAfterWalk = null;
      return;
    }
    _direction = _catX < _homeX ? 1.0 : -1.0;
  }

  void _randomStateChange() {
    final states = [CatState.idle, CatState.walk, CatState.sleep, CatState.wantFish];
    const weights = [0.35, 0.35, 0.2, 0.1];
    final rand = Random().nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < states.length; i++) {
      cumulative += weights[i];
      if (rand < cumulative) {
        setState(states[i]);
        return;
      }
    }
    setState(CatState.idle);
  }

  // Interactions
  void handleTap() {
    _showMeow();
    setState(CatState.jump);
  }

  void handlePet() {
    _showHearts();
    _showBubble('咕噜咕噜~', color: 0xFFB6C1, yOffset: 55, duration: 1.0);
  }

  void _showMeow() {
    _removeMeow();
    _meowBubble = _showBubble('喵~', color: 0xFF69B4, yOffset: 55, duration: 0.8);
  }

  void _removeMeow() {
    if (_meowBubble != null) {
      _bubbles.remove(_meowBubble);
      _meowBubble = null;
    }
  }

  BubbleData _showBubble(String text, {required int color, required double yOffset, required double duration}) {
    final bubble = BubbleData(
      text: text,
      color: color,
      x: _catX - 20,
      startY: _catY - yOffset,
      duration: duration,
    );
    _bubbles.add(bubble);
    notifyListeners();
    return bubble;
  }

  void _showHearts() {
    final heartEmojis = ['❤️', '💕', '💗', '💖', '🧡'];
    final rand = Random();
    for (int i = 0; i < 5; i++) {
      _hearts.add(HeartData(
        emoji: heartEmojis[i],
        startX: _catX + (rand.nextDouble() * 60 - 30),
        startY: _catY - 40 - i * 10 - (rand.nextDouble() * 20 + 10),
        offsetX: rand.nextDouble() * 20 - 10,
        delay: i * 0.08,
      ));
    }
    notifyListeners();
  }

  // State setters for context menu
  void setIdle() => setState(CatState.idle);
  void setWalk() => setState(CatState.walk);
  void setSleep() => setState(CatState.sleep);
  void setWantFish() => setState(CatState.wantFish);
}
