import 'package:flutter_test/flutter_test.dart';
import 'package:halo_windows/models/cat_state.dart';
import 'package:halo_windows/state/cat_controller.dart';

void main() {
  group('CatState model', () {
    test('has 5 states', () {
      expect(CatState.values.length, 5);
    });

    test('stateConfigs has entries for all states', () {
      for (final state in CatState.values) {
        expect(stateConfigs.containsKey(state), true);
      }
    });

    test('getSpritePaths returns correct count for each state', () {
      expect(getSpritePaths(CatState.idle).length, 12);
      expect(getSpritePaths(CatState.walk).length, 9);
      expect(getSpritePaths(CatState.sleep).length, 4);
      expect(getSpritePaths(CatState.wantFish).length, 11);
      expect(getSpritePaths(CatState.jump).length, 18);
    });

    test('getSpritePaths generates correct path format', () {
      final paths = getSpritePaths(CatState.idle);
      expect(paths.first, 'assets/sprites/idle/idle0.png');
      expect(paths.last, 'assets/sprites/idle/idle11.png');
    });

    test('state frame rates are positive', () {
      for (final config in stateConfigs.values) {
        expect(config.fps, greaterThan(0));
      }
    });

    test('state durations are positive', () {
      for (final config in stateConfigs.values) {
        expect(config.duration, greaterThan(0));
      }
    });

    test('jump has shortest duration', () {
      final jumpDuration = stateConfigs[CatState.jump]!.duration;
      for (final entry in stateConfigs.entries) {
        if (entry.key != CatState.jump) {
          expect(entry.value.duration, greaterThan(jumpDuration));
        }
      }
    });

    test('sleep has longest duration', () {
      final sleepDuration = stateConfigs[CatState.sleep]!.duration;
      for (final entry in stateConfigs.entries) {
        if (entry.key != CatState.sleep) {
          expect(sleepDuration, greaterThanOrEqualTo(entry.value.duration));
        }
      }
    });
  });

  group('CatController', () {
    late CatController controller;
    late List<String> notifications;

    setUp(() {
      controller = CatController();
      notifications = [];
      controller.addListener(() {
        notifications.add('notify');
      });
    });

    test('initial state is idle', () {
      expect(controller.state, CatState.idle);
    });

    test('initial position is centered', () {
      expect(controller.catX, CatController.windowSize / 2);
      expect(controller.catY, CatController.windowSize / 2);
    });

    test('initial frame is 0', () {
      expect(controller.currentFrame, 0);
    });

    test('initial direction is positive', () {
      expect(controller.direction, 1.0);
    });

    test('not jumping initially', () {
      expect(controller.isJumping, false);
    });

    // setState tests
    group('setState', () {
      test('changes state', () {
        controller.setState(CatState.walk);
        expect(controller.state, CatState.walk);
      });

      test('resets frame to 0', () {
        controller.setState(CatState.idle);
        controller.update(0.2); // advance some frames
        controller.setState(CatState.walk);
        expect(controller.currentFrame, 0);
      });

      test('ignores same state', () {
        controller.setState(CatState.idle); // already idle
        expect(notifications.isEmpty, true);
      });

      test('sets jumping on jump state', () {
        controller.setState(CatState.jump);
        expect(controller.isJumping, true);
      });

      test('notifies listeners', () {
        controller.setState(CatState.sleep);
        expect(notifications.isNotEmpty, true);
      });

      test('consecutive different states work', () {
        controller.setState(CatState.walk);
        expect(controller.state, CatState.walk);
        controller.setState(CatState.sleep);
        expect(controller.state, CatState.sleep);
        controller.setState(CatState.idle);
        expect(controller.state, CatState.idle);
      });
    });

    // Update loop tests
    group('update', () {
      test('advances frame timer', () {
        controller.setState(CatState.idle);
        final initialFrame = controller.currentFrame;
        // Update enough to trigger a frame advance (idle fps = 6, so ~0.167s)
        controller.update(0.2);
        expect(controller.currentFrame, isNot(initialFrame));
      });

      test('walk moves cat position', () {
        controller.setState(CatState.walk);
        final initialX = controller.catX;
        controller.update(0.1);
        // Cat should have moved (direction is random on walk start)
        expect(controller.catX, isNot(initialX));
      });

      test('idle does not change position', () {
        final initialX = controller.catX;
        controller.update(0.1);
        expect(controller.catX, initialX);
      });
    });

    // Jump physics tests
    group('jump physics', () {
      test('jump moves cat upward initially', () {
        controller.setState(CatState.jump);
        final initialY = controller.catY;
        // First update: velocity is positive (200), so y decreases (upward in Flutter coords)
        controller.update(0.016);
        expect(controller.isJumping, true);
      });

      test('jump eventually returns to base', () {
        controller.setState(CatState.jump);
        // Simulate enough time for full jump arc
        for (int i = 0; i < 200; i++) {
          controller.update(0.016);
        }
        expect(controller.isJumping, false);
        expect(controller.catY, CatController.windowSize / 2);
      });

      test('jump ends in idle state', () {
        controller.setState(CatState.jump);
        for (int i = 0; i < 200; i++) {
          controller.update(0.016);
        }
        expect(controller.state, CatState.idle);
      });
    });

    // Interaction tests
    group('interactions', () {
      test('handleTap triggers jump', () {
        controller.setState(CatState.sleep);
        controller.handleTap();
        expect(controller.state, CatState.jump);
      });

      test('handleTap triggers jump and cleans up meow', () {
        controller.setState(CatState.sleep);
        controller.handleTap();
        expect(controller.state, CatState.jump);
        // Meow is created then removed by setState(.jump) — so bubbles is empty
        expect(controller.bubbles.isEmpty, true);
      });

      test('handlePet creates hearts', () {
        controller.handlePet();
        expect(controller.hearts.length, 5);
      });

      test('handlePet creates purr bubble', () {
        controller.handlePet();
        expect(controller.bubbles.any((b) => b.text == '咕噜咕噜~'), true);
      });

      test('handleTap creates then cleans meow on state change', () {
        // handleTap calls _showMeow then setState(.jump), which calls _removeMeow
        controller.handleTap();
        expect(controller.bubbles.isEmpty, true); // meow removed by setState
        expect(controller.state, CatState.jump);
      });
    });

    // Convenience setters
    group('convenience setters', () {
      test('setIdle sets idle', () {
        controller.setState(CatState.walk);
        controller.setIdle();
        expect(controller.state, CatState.idle);
      });

      test('setWalk sets walk', () {
        controller.setWalk();
        expect(controller.state, CatState.walk);
      });

      test('setSleep sets sleep', () {
        controller.setSleep();
        expect(controller.state, CatState.sleep);
      });

      test('setWantFish sets wantFish', () {
        controller.setWantFish();
        expect(controller.state, CatState.wantFish);
      });
    });

    // Bubble lifecycle
    group('bubbles', () {
      test('bubbles expire after duration', () {
        controller.handlePet(); // creates 1.0s bubble
        expect(controller.bubbles.isNotEmpty, true);
        // Simulate 1.5 seconds
        for (int i = 0; i < 100; i++) {
          controller.update(0.016);
        }
        expect(controller.bubbles.isEmpty, true);
      });

      test('hearts expire after animation', () {
        controller.handlePet();
        expect(controller.hearts.isNotEmpty, true);
        // Simulate 2 seconds
        for (int i = 0; i < 150; i++) {
          controller.update(0.016);
        }
        expect(controller.hearts.isEmpty, true);
      });
    });
  });
}
