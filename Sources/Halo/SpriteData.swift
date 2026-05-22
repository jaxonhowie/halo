import Cocoa

enum SpriteData {
    static let idleTextureNames = (0...11).map { "idle\($0)" }
    static let walkTextureNames = (0...8).map { "walk\($0)" }
    static let sleepTextureNames = (0...3).map { "sleep\($0)" }
    static let wantFishTextureNames = (0...10).map { "wantFish\($0)" }
    static let jumpTextureNames = (0...17).map { "jump\($0)" }
}

extension NSColor {
    convenience init?(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
