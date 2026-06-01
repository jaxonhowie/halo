import ImageIO
import SpriteKit

enum CatState: CaseIterable {
    case idle, walk, sleep, wantFish, jump
}

// MARK: - Countdown Bubble

private class CountdownBubble {
    let container: SKNode
    let label: SKLabelNode
    let emoji: String
    var startDate: Date?
    var interval: TimeInterval = 0
    var lastSecond: Int = -1

    init(emoji: String, fontSize: CGFloat = 20) {
        self.emoji = emoji
        container = SKNode()
        container.zPosition = 25
        container.isHidden = true
        label = SKLabelNode(text: "")
        label.fontName = "Helvetica-Bold"
        label.fontSize = fontSize
        label.fontColor = .white
        container.addChild(label)
    }

    func start(interval: TimeInterval, position: CGPoint) {
        startDate = Date()
        self.interval = interval
        lastSecond = -1
        container.isHidden = false
        container.position = position
        update()
    }

    func clear() {
        container.isHidden = true
        label.text = ""
        startDate = nil
        lastSecond = -1
    }

    func update() {
        guard let startDate = startDate else { return }
        let remaining = max(0, interval - Date().timeIntervalSince(startDate))
        let seconds = Int(ceil(remaining))
        guard seconds != lastSecond else { return }
        lastSecond = seconds
        if seconds <= 0 { clear(); return }
        let m = seconds / 60, s = seconds % 60
        label.text = m > 0 ? "\(emoji) \(m):\(String(format: "%02d", s))" : "\(emoji) \(s)s"
    }
}

// MARK: - Cat Sprite Scene

class CatSpriteScene: SKScene {
    private let maxDisplaySize = CGSize(width: 144, height: 148)
    private let walkRange: CGFloat = 36.0
    private let walkSpeed: CGFloat = 30.0

    private var catNode: SKSpriteNode!
    private var currentState: CatState = .idle
    private var currentFrame = 0
    private var frameTimer: TimeInterval = 0
    private var stateTimer: TimeInterval = 0
    private var direction: CGFloat = 1.0
    private var isJumping = false
    private var jumpVelocity: CGFloat = 0
    private var catY: CGFloat = 0
    private var homeX: CGFloat = 0
    private var pendingStateAfterWalk: CatState?
    private var meowLabel: SKLabelNode?

    // Texture lookup
    private lazy var textures: [CatState: [SKTexture]] = [
        .idle: loadTextures(named: SpriteData.idleTextureNames, sub: "idle"),
        .walk: loadTextures(named: SpriteData.walkTextureNames, sub: "walk"),
        .sleep: loadTextures(named: SpriteData.sleepTextureNames, sub: "sleep"),
        .wantFish: loadTextures(named: SpriteData.wantFishTextureNames, sub: "wantFish"),
        .jump: loadTextures(named: SpriteData.jumpTextureNames, sub: "jump"),
    ]

    private let stateFrameRates: [CatState: Double] = [
        .idle: 6, .walk: 6, .sleep: 1, .wantFish: 4, .jump: 4
    ]
    private let stateDurations: [CatState: Double] = [
        .idle: 5, .walk: 6, .sleep: 10, .wantFish: 5, .jump: 0.6
    ]

    // Countdowns
    private lazy var walkBubble = CountdownBubble(emoji: "🚶")
    private lazy var waterBubble = CountdownBubble(emoji: "💧")

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        addChild(walkBubble.container)
        addChild(waterBubble.container)
        setupCat()
        setState(.idle)
    }

    // MARK: - Setup

    private func setupCat() {
        let frames = textures[.idle] ?? []
        catNode = SKSpriteNode(texture: frames.first, size: displaySize(for: frames.first))
        catNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        catNode.zPosition = 10
        addChild(catNode)
        catY = catNode.position.y
        homeX = catNode.position.x
    }

    private func loadTextures(named names: [String], sub: String) -> [SKTexture] {
        names.compactMap { name in
            let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: sub)
                ?? Bundle.module.url(forResource: name, withExtension: "png")
            guard let url, let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
            let t = SKTexture(cgImage: img)
            t.filteringMode = .nearest
            return t
        }
    }

    private func displaySize(for texture: SKTexture?) -> CGSize {
        guard let texture else { return maxDisplaySize }
        let s = texture.size()
        let scale = min(maxDisplaySize.width / s.width, maxDisplaySize.height / s.height)
        return CGSize(width: s.width * scale, height: s.height * scale)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval = 1.0 / 60.0
        frameTimer += dt
        stateTimer += dt

        if frameTimer >= 1.0 / (stateFrameRates[currentState] ?? 4) {
            frameTimer = 0
            advanceFrame()
        }

        if isJumping {
            jumpVelocity -= 400 * CGFloat(dt)
            catNode.position.y += jumpVelocity * CGFloat(dt)
            if catNode.position.y <= catY {
                catNode.position.y = catY
                isJumping = false
                jumpVelocity = 0
                setState(.idle)
            }
        }

        walkBubble.update()
        waterBubble.update()

        if currentState == .walk {
            catNode.position.x += walkSpeed * direction * CGFloat(dt)
            let margin: CGFloat = 20
            let maxX = min(size.width - margin, homeX + walkRange)
            let minX = max(margin, homeX - walkRange)
            if pendingStateAfterWalk != nil {
                if abs(catNode.position.x - homeX) <= 1.0 {
                    catNode.position.x = homeX
                    setState(pendingStateAfterWalk ?? .idle)
                    pendingStateAfterWalk = nil
                } else {
                    direction = catNode.position.x < homeX ? 1 : -1
                    catNode.xScale = -direction
                }
            } else if catNode.position.x > maxX {
                catNode.position.x = maxX; direction = -1; catNode.xScale = 1
            } else if catNode.position.x < minX {
                catNode.position.x = minX; direction = 1; catNode.xScale = -1
            }
        }

        if stateTimer >= (stateDurations[currentState] ?? 5) && !isJumping {
            currentState == .walk ? beginWalkReturn() : randomStateChange()
        }
    }

    private func advanceFrame() {
        guard let frames = textures[currentState], !frames.isEmpty else { return }
        currentFrame = (currentFrame + 1) % frames.count
        catNode.texture = frames[currentFrame]
        catNode.size = displaySize(for: frames[currentFrame])
        if currentState == .walk { catNode.xScale = -direction }
    }

    // MARK: - State Management

    func setState(_ newState: CatState) {
        guard currentState != newState else { return }
        currentState = newState
        currentFrame = 0; frameTimer = 0; stateTimer = 0
        if newState != .walk { pendingStateAfterWalk = nil }
        removeMeow()

        let frames = textures[newState] ?? []
        catNode.texture = frames.first
        catNode.size = displaySize(for: frames.first)
        catNode.xScale = newState == .walk ? -direction : 1

        if newState == .jump { isJumping = true; jumpVelocity = 200 }
    }

    private func beginWalkReturn() {
        guard pendingStateAfterWalk == nil else { return }
        pendingStateAfterWalk = Bool.random() ? .idle : .sleep
        if abs(catNode.position.x - homeX) <= 1.0 {
            catNode.position.x = homeX
            setState(pendingStateAfterWalk ?? .idle)
            pendingStateAfterWalk = nil
            return
        }
        direction = catNode.position.x < homeX ? 1 : -1
        catNode.xScale = -direction
    }

    private func randomStateChange() {
        let states: [CatState] = [.idle, .walk, .sleep, .wantFish]
        let weights = [0.35, 0.35, 0.2, 0.1]
        let rand = Double.random(in: 0..<1)
        var cumulative = 0.0
        for (i, state) in states.enumerated() {
            cumulative += weights[i]
            if rand < cumulative {
                if state == .walk { direction = Bool.random() ? 1 : -1 }
                setState(state)
                return
            }
        }
        setState(.idle)
    }

    // MARK: - Interaction

    func handleTap() {
        showMeow()
        setState(.jump)
    }

    func handlePet() {
        showHearts()
        showBubble("咕噜咕噜~", color: 0xFFB6C1, yOffset: 55, duration: 1.0)
    }

    private func showMeow() {
        removeMeow()
        let label = showBubble("喵~", color: 0xFF69B4, yOffset: 55, duration: 0.8)
        meowLabel = label
    }

    private func removeMeow() {
        meowLabel?.removeFromParent()
        meowLabel = nil
    }

    @discardableResult
    private func showBubble(_ text: String, color: UInt, yOffset: CGFloat, duration: TimeInterval) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica-Bold"
        label.fontSize = 14
        label.fontColor = NSColor(hex: color)
        label.position = CGPoint(x: catNode.position.x, y: catNode.position.y + yOffset)
        label.zPosition = 20
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 20, duration: duration), SKAction.fadeOut(withDuration: duration)]),
            SKAction.removeFromParent()
        ]))
        return label
    }

    private func showHearts() {
        let hearts = ["❤️", "💕", "💗", "💖", "🧡"]
        for i in 0..<5 {
            let label = SKLabelNode(text: hearts[i])
            label.fontSize = 16
            label.zPosition = 20
            label.position = CGPoint(
                x: catNode.position.x + CGFloat.random(in: -30...30),
                y: catNode.position.y + 40 + CGFloat(i) * 10 + CGFloat.random(in: 10...30)
            )
            label.alpha = 0
            addChild(label)
            label.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.08),
                SKAction.fadeIn(withDuration: 0.15),
                SKAction.group([SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 30, duration: 0.8), SKAction.fadeOut(withDuration: 0.6)]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Countdown API

    func startWalkCountdown(interval: TimeInterval) {
        walkBubble.start(interval: interval, position: CGPoint(x: size.width / 2, y: size.height - 25))
    }
    func clearWalkCountdown() { walkBubble.clear() }
    func startWaterCountdown(interval: TimeInterval) {
        waterBubble.start(interval: interval, position: CGPoint(x: size.width / 2, y: size.height - 50))
    }
    func clearWaterCountdown() { waterBubble.clear() }
}
