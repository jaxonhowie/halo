import 'package:flutter_test/flutter_test.dart';
import 'package:halo_windows/models/cat_state.dart';

void main() {
  test('CatState has 5 states', () {
    expect(CatState.values.length, 5);
  });

  test('stateConfigs has entries for all states', () {
    for (final state in CatState.values) {
      expect(stateConfigs.containsKey(state), true);
    }
  });

  test('getSpritePaths returns correct count', () {
    expect(getSpritePaths(CatState.idle).length, 12);
    expect(getSpritePaths(CatState.walk).length, 9);
    expect(getSpritePaths(CatState.sleep).length, 4);
    expect(getSpritePaths(CatState.wantFish).length, 11);
    expect(getSpritePaths(CatState.jump).length, 18);
  });
}
