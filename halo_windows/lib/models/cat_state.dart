enum CatState { idle, walk, sleep, wantFish, jump }

class StateConfig {
  final int frameCount;
  final double fps;
  final double duration;
  final String assetPrefix;

  const StateConfig({
    required this.frameCount,
    required this.fps,
    required this.duration,
    required this.assetPrefix,
  });
}

const Map<CatState, StateConfig> stateConfigs = {
  CatState.idle: StateConfig(frameCount: 12, fps: 6, duration: 5, assetPrefix: 'idle'),
  CatState.walk: StateConfig(frameCount: 9, fps: 6, duration: 6, assetPrefix: 'walk'),
  CatState.sleep: StateConfig(frameCount: 4, fps: 1, duration: 10, assetPrefix: 'sleep'),
  CatState.wantFish: StateConfig(frameCount: 11, fps: 4, duration: 5, assetPrefix: 'wantFish'),
  CatState.jump: StateConfig(frameCount: 18, fps: 4, duration: 0.6, assetPrefix: 'jump'),
};

List<String> getSpritePaths(CatState state) {
  final config = stateConfigs[state]!;
  return List.generate(
    config.frameCount,
    (i) => 'assets/sprites/${config.assetPrefix}/${config.assetPrefix}$i.png',
  );
}
