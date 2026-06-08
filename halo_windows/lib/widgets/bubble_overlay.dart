import 'package:flutter/material.dart';
import '../state/cat_controller.dart';

class BubbleOverlay extends StatelessWidget {
  final CatController controller;

  const BubbleOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: controller.bubbles.map((bubble) {
            return Positioned(
              left: bubble.x,
              top: bubble.y,
              child: Opacity(
                opacity: bubble.opacity,
                child: Text(
                  bubble.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(bubble.color | 0xFF000000),
                    shadows: const [
                      Shadow(offset: Offset(1, 1), color: Colors.black54, blurRadius: 2),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
