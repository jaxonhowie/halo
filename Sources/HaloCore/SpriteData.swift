/// Sprite texture name definitions for each animation state
public enum SpriteData {
    public static let idleTextureNames = (0...11).map { "idle\($0)" }
    public static let walkTextureNames = (0...8).map { "walk\($0)" }
    public static let sleepTextureNames = (0...3).map { "sleep\($0)" }
    public static let wantFishTextureNames = (0...10).map { "wantFish\($0)" }
    public static let jumpTextureNames = (0...17).map { "jump\($0)" }

    /// Frame rates per state (frames per second)
    public static let stateFrameRates: [CatState: Double] = [
        .idle: 6, .walk: 6, .sleep: 1, .wantFish: 4, .jump: 4
    ]

    /// Duration (in seconds) before automatic state transition
    public static let stateDurations: [CatState: Double] = [
        .idle: 5, .walk: 6, .sleep: 10, .wantFish: 5, .jump: 0.6
    ]

    /// Transition weights for random state selection (excluding jump)
    public static let transitionWeights: [CatState: Double] = [
        .idle: 0.35, .walk: 0.35, .sleep: 0.20, .wantFish: 0.10
    ]
}
