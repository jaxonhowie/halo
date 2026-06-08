import 'package:flutter/material.dart';
import '../state/cat_controller.dart';

class HeartsEffect extends StatelessWidget {
  final CatController controller;

  const HeartsEffect({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: controller.hearts
              .where((h) => h.started && h.opacity > 0)
              .map((heart) {
            return Positioned(
              left: heart.startX + heart.offsetX,
              top: heart.y,
              child: Opacity(
                opacity: heart.opacity,
                child: Text(
                  heart.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
