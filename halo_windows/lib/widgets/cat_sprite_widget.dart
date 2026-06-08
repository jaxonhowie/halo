import 'package:flutter/material.dart';
import '../models/cat_state.dart';
import '../state/cat_controller.dart';

class CatSpriteWidget extends StatelessWidget {
  final CatController controller;

  const CatSpriteWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final paths = getSpritePaths(controller.state);
        final frameIndex = controller.currentFrame % paths.length;
        final imagePath = paths[frameIndex];
        final flipX = controller.state == CatState.walk && controller.direction < 0;

        return Transform.translate(
          offset: Offset(controller.catX - 104, controller.catY - 104),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              flipX ? -1.0 : 1.0,
              1.0,
              1.0,
            ),
            child: Image.asset(
              imagePath,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              width: 144,
              height: 148,
              errorBuilder: (_, e, st) => const SizedBox(width: 144, height: 148),
            ),
          ),
        );
      },
    );
  }
}
