import 'dart:async';

import 'package:win32/win32.dart';

/// Win32 全局键盘活动检测服务
/// 使用 GetAsyncKeyState 轮询检测系统级按键活动
/// 50ms 轮询间隔对桌面宠物完全够用，且无需消息泵
class KeyboardHookService {
  Timer? _timer;
  bool _lastAnyKeyDown = false;
  final void Function() onKeyEvent;

  KeyboardHookService({required this.onKeyEvent});

  void start() {
    // 每 50ms 轮询一次键盘状态
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _checkKeyboard();
    });
  }

  void _checkKeyboard() {
    bool anyKeyDown = false;

    // 检查常用按键的按下状态 (0x08=Backspace 到 0xFE=VK_OEM_CLEAR)
    // 只检查修饰键和字母数字键，避免误触发
    for (int vk in _watchedKeys) {
      final state = GetAsyncKeyState(vk);
      // 0x8000 = 当前是否按下, 0x0001 = 自上次调用以来是否按下
      if (state & 0x8000 != 0) {
        anyKeyDown = true;
        break;
      }
    }

    // 只在按键状态从"无"变为"有"时触发事件
    if (anyKeyDown && !_lastAnyKeyDown) {
      onKeyEvent();
    }
    _lastAnyKeyDown = anyKeyDown;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }

  /// 监视的虚拟键码列表
  /// 包含字母、数字、常用功能键，排除鼠标按钮
  static const _watchedKeys = [
    // 字母 A-Z (0x41-0x5A)
    0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A,
    0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54,
    0x55, 0x56, 0x57, 0x58, 0x59, 0x5A,
    // 数字 0-9 (0x30-0x39)
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
    // 空格、回车、退格、Tab、Escape
    0x20, 0x0D, 0x08, 0x09, 0x1B,
    // Shift、Ctrl、Alt
    0x10, 0x11, 0x12,
    // 方向键
    0x25, 0x26, 0x27, 0x28,
  ];
}
