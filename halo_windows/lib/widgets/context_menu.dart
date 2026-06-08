import 'package:flutter/material.dart';
import '../state/cat_controller.dart';

Future<void> showCatContextMenu(
  BuildContext context,
  Offset position,
  CatController controller,
  VoidCallback onShowStats,
  VoidCallback onQuit,
) async {
  final result = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    ),
    items: [
      const PopupMenuItem(value: 'idle', child: Text('待机')),
      const PopupMenuItem(value: 'walk', child: Text('走动')),
      const PopupMenuItem(value: 'sleep', child: Text('睡觉')),
      const PopupMenuItem(value: 'wantFish', child: Text('想吃鱼')),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'stats', child: Text('查看统计')),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'quit', child: Text('退出')),
    ],
  );

  switch (result) {
    case 'idle':
      controller.setIdle();
      break;
    case 'walk':
      controller.setWalk();
      break;
    case 'sleep':
      controller.setSleep();
      break;
    case 'wantFish':
      controller.setWantFish();
      break;
    case 'stats':
      onShowStats();
      break;
    case 'quit':
      onQuit();
      break;
  }
}
