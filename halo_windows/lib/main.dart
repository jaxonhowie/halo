import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  await windowManager.ensureInitialized();

  final savedX = StorageService.getWindowX();
  final savedY = StorageService.getWindowY();

  const windowOptions = WindowOptions(
    size: Size(208, 208),
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    alwaysOnTop: true,
    skipTaskbar: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setSkipTaskbar(true);
    if (savedX != null && savedY != null) {
      await windowManager.setPosition(Offset(savedX, savedY));
    }
    await windowManager.show();
    await windowManager.focus();
  });

  // System tray (Windows only)
  if (Platform.isWindows) {
    final systemTray = SystemTray();
    await systemTray.initSystemTray(
      title: 'Halo',
      iconPath: 'assets/app_icon.ico',
      toolTip: 'Halo Desktop Pet',
    );

    final menu = Menu();
    menu.buildFrom([
      MenuItemLabel(label: '显示', onClicked: (_) => windowManager.show()),
      MenuItemLabel(label: '退出', onClicked: (_) => exit(0)),
    ]);
    await systemTray.setContextMenu(menu);
  }

  runApp(const HaloApp());
}
