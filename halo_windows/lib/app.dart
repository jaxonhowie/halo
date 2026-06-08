import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';
import 'state/cat_controller.dart';
import 'services/session_service.dart';
import 'services/reminder_service.dart';
import 'services/storage_service.dart';
import 'services/keyboard_hook_service.dart';
import 'widgets/cat_sprite_widget.dart';
import 'widgets/bubble_overlay.dart';
import 'widgets/hearts_effect.dart';
import 'widgets/countdown_overlay.dart';
import 'widgets/context_menu.dart';
import 'widgets/stats_panel.dart';

class HaloApp extends StatelessWidget {
  const HaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const PetHome(),
    );
  }
}

class PetHome extends StatefulWidget {
  const PetHome({super.key});

  @override
  State<PetHome> createState() => _PetHomeState();
}

class _PetHomeState extends State<PetHome> with TickerProviderStateMixin {
  late final CatController _controller;
  late final SessionService _sessionService;
  late final ReminderService _reminderService;
  late final KeyboardHookService _keyboardHook;
  final GlobalKey<CountdownOverlayState> _countdownKey = GlobalKey();

  // Drag state
  bool _isDragging = false;
  Offset _dragStartPos = Offset.zero;
  Offset _windowDragStartPos = Offset.zero;
  Timer? _singleClickTimer;

  // Animation ticker
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = CatController();
    _sessionService = SessionService();

    _reminderService = ReminderService(
      onWaterReminder: _showWaterReminder,
      onWalkReminder: _showWalkReminder,
      onWaterCountdownStart: () => _countdownKey.currentState?.startWater(),
      onWalkCountdownStart: () => _countdownKey.currentState?.startWalk(),
      onWaterCountdownClear: () => _countdownKey.currentState?.clearWater(),
      onWalkCountdownClear: () => _countdownKey.currentState?.clearWalk(),
    );

    // 启动全局键盘监听（仅 Windows 生效）
    _keyboardHook = KeyboardHookService(onKeyEvent: _onKeyEvent);
    if (Platform.isWindows) {
      _keyboardHook.start();
    }

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 1.0 / 60.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _controller.update(dt.clamp(0.0, 0.1));
  }

  void _onKeyEvent() {
    _sessionService.onKeyboardActivity();
    _reminderService.onKeyboardActivity();
  }

  void _onTap() {
    _onKeyEvent(); // 鼠标交互也算活动
    _controller.handleTap();
  }

  void _onDoubleTap() {
    _onKeyEvent();
    _controller.handlePet();
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = false;
    _dragStartPos = details.globalPosition;
    _singleClickTimer?.cancel();
  }

  void _onDragUpdate(DragUpdateDetails details) async {
    if (!_isDragging) {
      final dx = (details.globalPosition.dx - _dragStartPos.dx).abs();
      final dy = (details.globalPosition.dy - _dragStartPos.dy).abs();
      if (dx > 3 || dy > 3) {
        _isDragging = true;
        final pos = await windowManager.getPosition();
        _windowDragStartPos = pos;
      }
    }
    if (_isDragging) {
      final delta = details.globalPosition - _dragStartPos;
      await windowManager.setPosition(
        Offset(_windowDragStartPos.dx + delta.dx, _windowDragStartPos.dy + delta.dy),
      );
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) {
      _singleClickTimer?.cancel();
      _singleClickTimer = Timer(const Duration(milliseconds: 250), () {
        _onTap();
      });
    } else {
      _saveWindowPosition();
    }
    _isDragging = false;
  }

  Future<void> _saveWindowPosition() async {
    final pos = await windowManager.getPosition();
    await StorageService.setWindowPosition(pos.dx, pos.dy);
  }

  void _showContextMenu(TapDownDetails details) {
    showCatContextMenu(
      context,
      details.globalPosition,
      _controller,
      _showStatsPanel,
      () => exit(0),
    );
  }

  void _showStatsPanel() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => const StatsPanel(),
    );
  }

  void _showWaterReminder() {
    _showReminderDialog(
      message: '该喝水了哟~',
      info: '记得休息一下，保持健康！',
      button: '喝过啦',
    );
  }

  void _showWalkReminder() {
    _showReminderDialog(
      message: '该起身走动啦~',
      info: '久坐伤身，起来活动一下吧！',
      button: '走过了',
    );
  }

  Future<void> _showReminderDialog({
    required String message,
    required String info,
    required String button,
  }) async {
    final savedPos = await windowManager.getPosition();
    // Center window on screen
    await windowManager.setAlignment(Alignment.center);

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(message),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(button),
          ),
        ],
      ),
    );

    // Restore position
    await windowManager.setPosition(savedPos);
    await _saveWindowPosition();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _singleClickTimer?.cancel();
    _keyboardHook.dispose();
    _controller.dispose();
    _sessionService.dispose();
    _reminderService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Handled by onPanEnd
      onDoubleTap: _onDoubleTap,
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onSecondaryTapDown: _showContextMenu,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            CatSpriteWidget(controller: _controller),
            BubbleOverlay(controller: _controller),
            HeartsEffect(controller: _controller),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CountdownOverlay(
                key: _countdownKey,
                waterInterval: ReminderService.waterInterval,
                walkInterval: ReminderService.walkInterval,
                onWaterStart: () {},
                onWalkStart: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
