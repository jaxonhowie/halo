import ImageIO
import SpriteKit

enum CatState {
    case idle
    case walk
    case sleep
    case wantFish
    case jump
}

class CatSpriteScene: SKScene {
    private var catNode: SKSpriteNode!
    private lazy var idleTextures = loadIdleTextures()
    private lazy var walkTextures = loadWalkTextures()
    private lazy var sleepTextures = loadSleepTextures()
    private lazy var wantFishTextures = loadWantFishTextures()
    private lazy var jumpTextures = loadJumpTextures()
    private var currentState: CatState = .idle
    private var currentFrame = 0
    private var frameTimer: TimeInterval = 0
    private var stateTimer: TimeInterval = 0
    private var direction: CGFloat = 1.0  // 1 = right, -1 = left
    private var walkSpeed: CGFloat = 30.0
    private var isJumping = false
    private var jumpVelocity: CGFloat = 0
    private var catY: CGFloat = 0
    private var homeX: CGFloat = 0
    private var pendingStateAfterWalk: CatState?
    private var meowLabel: SKLabelNode?
    // Walk countdown bubble
    private var walkCountdownContainer: SKNode?
    private var walkCountdownLabel: SKLabelNode?
    private var walkCountdownStartDate: Date?
    private var walkCountdownInterval: TimeInterval = 0
    private var walkLastCountdownSecond: Int = -1
    // Water countdown bubble
    private var waterCountdownContainer: SKNode?
    private var waterCountdownLabel: SKLabelNode?
    private var waterCountdownStartDate: Date?
    private var waterCountdownInterval: TimeInterval = 0
    private var waterLastCountdownSecond: Int = -1
    private let walkRange: CGFloat = 36.0
    private let idleMaxDisplaySize = CGSize(width: 144, height: 148)
    private let walkMaxDisplaySize = CGSize(width: 144, height: 148)
    private let sleepMaxDisplaySize = CGSize(width: 144, height: 148)
    private let wantFishMaxDisplaySize = CGSize(width: 144, height: 148)
    private let jumpMaxDisplaySize = CGSize(width: 144, height: 148)

    // Frame rates for each state (fps)
    private var stateFrameRates: [CatState: Double] = [
        .idle: 6.0,
        .walk: 6.0,
        .sleep: 1.0,
        .wantFish: 4.0,
        .jump: 4.0,
    ]

    // Duration before auto state change
    private var stateDurations: [CatState: Double] = [
        .idle: 5.0,
        .walk: 6.0,
        .sleep: 10.0,
        .wantFish: 5.0,
        .jump: 0.6,
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupCat()
        setState(.idle)
    }

    private func setupCat() {
        let texture = idleTextures.first ?? SKTexture()
        catNode = SKSpriteNode(texture: texture, size: idleDisplaySize(for: texture))
        catNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        catNode.zPosition = 10
        addChild(catNode)
        catY = catNode.position.y
        homeX = catNode.position.x
    }

    private func loadIdleTextures() -> [SKTexture] {
        loadTextures(named: SpriteData.idleTextureNames, subdirectory: "idle")
    }

    private func loadWalkTextures() -> [SKTexture] {
        loadTextures(named: SpriteData.walkTextureNames, subdirectory: "walk")
    }

    private func loadSleepTextures() -> [SKTexture] {
        loadTextures(named: SpriteData.sleepTextureNames, subdirectory: "sleep")
    }

    private func loadWantFishTextures() -> [SKTexture] {
        loadTextures(named: SpriteData.wantFishTextureNames, subdirectory: "wantFish")
    }

    private func loadJumpTextures() -> [SKTexture] {
        loadTextures(named: SpriteData.jumpTextureNames, subdirectory: "jump")
    }

    private func loadTextures(named names: [String], subdirectory: String) -> [SKTexture] {
        names.compactMap { name in
            let resourceURL = Bundle.module.url(forResource: name, withExtension: "png")
                ?? Bundle.module.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
            guard let url = resourceURL,
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            let texture = SKTexture(cgImage: image)
            texture.filteringMode = .nearest
            return texture
        }
    }

    private func idleDisplaySize(for texture: SKTexture) -> CGSize {
        let textureSize = texture.size()
        let scale = min(
            idleMaxDisplaySize.width / textureSize.width,
            idleMaxDisplaySize.height / textureSize.height
        )
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private func walkDisplaySize(for texture: SKTexture) -> CGSize {
        let textureSize = texture.size()
        let scale = min(
            walkMaxDisplaySize.width / textureSize.width,
            walkMaxDisplaySize.height / textureSize.height
        )
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private func sleepDisplaySize(for texture: SKTexture) -> CGSize {
        let textureSize = texture.size()
        let scale = min(
            sleepMaxDisplaySize.width / textureSize.width,
            sleepMaxDisplaySize.height / textureSize.height
        )
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private func wantFishDisplaySize(for texture: SKTexture) -> CGSize {
        let textureSize = texture.size()
        let scale = min(
            wantFishMaxDisplaySize.width / textureSize.width,
            wantFishMaxDisplaySize.height / textureSize.height
        )
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private func jumpDisplaySize(for texture: SKTexture) -> CGSize {
        let textureSize = texture.size()
        let scale = min(
            jumpMaxDisplaySize.width / textureSize.width,
            jumpMaxDisplaySize.height / textureSize.height
        )
        return CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
    }

    private func applyWalkFacing() {
        catNode.xScale = -direction
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval = 1.0 / 60.0  // Fixed timestep

        frameTimer += dt
        stateTimer += dt

        // Update animation frame
        let frameRate = stateFrameRates[currentState] ?? 4.0
        if frameTimer >= 1.0 / frameRate {
            frameTimer = 0
            advanceFrame()
        }

        // Handle jump physics
        if isJumping {
            jumpVelocity -= 400 * CGFloat(dt)  // gravity
            catNode.position.y += jumpVelocity * CGFloat(dt)
            if catNode.position.y <= catY {
                catNode.position.y = catY
                isJumping = false
                jumpVelocity = 0
                setState(.idle)
            }
        }

        // Handle walk movement

        // Update countdown bubbles
        updateWalkCountdown()
        updateWaterCountdown()
        if currentState == .walk {
            catNode.position.x += walkSpeed * direction * CGFloat(dt)
            // Keep the cat pacing around its original resting position.
            let margin: CGFloat = 20
            let maxX = min(size.width - margin, homeX + walkRange)
            let minX = max(margin, homeX - walkRange)
            if pendingStateAfterWalk != nil {
                let returnThreshold: CGFloat = 1.0
                if abs(catNode.position.x - homeX) <= returnThreshold {
                    catNode.position.x = homeX
                    let nextState = pendingStateAfterWalk ?? .idle
                    pendingStateAfterWalk = nil
                    setState(nextState)
                } else {
                    direction = catNode.position.x < homeX ? 1 : -1
                    applyWalkFacing()
                }
            } else if catNode.position.x > maxX {
                catNode.position.x = maxX
                direction = -1
                applyWalkFacing()
            } else if catNode.position.x < minX {
                catNode.position.x = minX
                direction = 1
                applyWalkFacing()
            }
        }

        // Auto state transitions
        let duration = stateDurations[currentState] ?? 5.0
        if stateTimer >= duration && !isJumping {
            if currentState == .walk {
                beginWalkReturn()
            } else {
                randomStateChange()
            }
        }

    }

    private func advanceFrame() {
        switch currentState {
        case .idle:
            let frames = idleTextures
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = frames[currentFrame]
            catNode.size = idleDisplaySize(for: frames[currentFrame])
        case .walk:
            currentFrame = (currentFrame + 1) % walkTextures.count
            catNode.texture = walkTextures[currentFrame]
            catNode.size = walkDisplaySize(for: walkTextures[currentFrame])
            applyWalkFacing()
        case .sleep:
            currentFrame = (currentFrame + 1) % sleepTextures.count
            catNode.texture = sleepTextures[currentFrame]
            catNode.size = sleepDisplaySize(for: sleepTextures[currentFrame])
        case .wantFish:
            currentFrame = (currentFrame + 1) % wantFishTextures.count
            catNode.texture = wantFishTextures[currentFrame]
            catNode.size = wantFishDisplaySize(for: wantFishTextures[currentFrame])
        case .jump:
            currentFrame = (currentFrame + 1) % jumpTextures.count
            catNode.texture = jumpTextures[currentFrame]
            catNode.size = jumpDisplaySize(for: jumpTextures[currentFrame])
        }
    }

    // MARK: - State Management

    func setState(_ newState: CatState) {
        guard currentState != newState else { return }
        currentState = newState
        currentFrame = 0
        frameTimer = 0
        stateTimer = 0
        if newState != .walk {
            pendingStateAfterWalk = nil
        }

        removeMeow()

        switch newState {
        case .idle:
            let texture = idleTextures.first ?? SKTexture()
            catNode.texture = texture
            catNode.size = idleDisplaySize(for: texture)
            catNode.xScale = 1
        case .walk:
            let texture = walkTextures.first ?? SKTexture()
            catNode.texture = texture
            catNode.size = walkDisplaySize(for: texture)
            applyWalkFacing()
        case .sleep:
            let texture = sleepTextures.first ?? SKTexture()
            catNode.texture = texture
            catNode.size = sleepDisplaySize(for: texture)
            catNode.xScale = 1
        case .wantFish:
            let texture = wantFishTextures.first ?? SKTexture()
            catNode.texture = texture
            catNode.size = wantFishDisplaySize(for: texture)
            catNode.xScale = 1
        case .jump:
            let texture = jumpTextures.first ?? SKTexture()
            catNode.texture = texture
            catNode.size = jumpDisplaySize(for: texture)
            catNode.xScale = 1
            isJumping = true
            jumpVelocity = 200
        }
    }

    private func beginWalkReturn() {
        guard pendingStateAfterWalk == nil else { return }
        pendingStateAfterWalk = Bool.random() ? .idle : .sleep
        if abs(catNode.position.x - homeX) <= 1.0 {
            catNode.position.x = homeX
            let nextState = pendingStateAfterWalk ?? .idle
            pendingStateAfterWalk = nil
            setState(nextState)
            return
        }

        direction = catNode.position.x < homeX ? 1 : -1
        applyWalkFacing()
    }

    private func randomStateChange() {
        let states: [CatState] = [.idle, .walk, .sleep, .wantFish]
        let weights = [0.35, 0.35, 0.2, 0.1]  // probability weights
        let rand = Double.random(in: 0..<1)
        var cumulative = 0.0
        for (i, state) in states.enumerated() {
            cumulative += weights[i]
            if rand < cumulative {
                if state == .walk {
                    direction = Bool.random() ? 1 : -1
                }
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

    private func showMeow() {
        removeMeow()
        let label = SKLabelNode(text: "喵~")
        label.fontName = "Helvetica-Bold"
        label.fontSize = 14
        label.fontColor = NSColor(hex: 0xFF69B4)
        label.position = CGPoint(x: catNode.position.x, y: catNode.position.y + 55)
        label.zPosition = 20
        label.alpha = 1.0
        addChild(label)
        meowLabel = label

        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([group, remove]))
    }

    private func removeMeow() {
        meowLabel?.removeFromParent()
        meowLabel = nil
    }

    // MARK: - Countdown Bubble

    // MARK: - Walk Countdown

    func startWalkCountdown(interval: TimeInterval) {
        walkCountdownStartDate = Date()
        walkCountdownInterval = interval
        walkLastCountdownSecond = -1

        if walkCountdownContainer == nil {
            let container = SKNode()
            container.zPosition = 25
            addChild(container)
            walkCountdownContainer = container

            let label = SKLabelNode(text: "")
            label.fontName = "Helvetica-Bold"
            label.fontSize = 20
            label.fontColor = .white
            container.addChild(label)
            walkCountdownLabel = label
        }

        walkCountdownContainer?.isHidden = false
        walkCountdownContainer?.position = CGPoint(x: size.width / 2, y: size.height - 25)
        updateWalkCountdown()
    }

    func clearWalkCountdown() {
        walkCountdownContainer?.isHidden = true
        walkCountdownLabel?.text = ""
        walkCountdownStartDate = nil
        walkLastCountdownSecond = -1
    }

    private func updateWalkCountdown() {
        guard let startDate = walkCountdownStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, walkCountdownInterval - elapsed)
        let seconds = Int(ceil(remaining))

        guard seconds != walkLastCountdownSecond else { return }
        walkLastCountdownSecond = seconds

        if seconds <= 0 {
            clearWalkCountdown()
            return
        }

        let minutes = seconds / 60
        let secs = seconds % 60
        let text = minutes > 0 ? "🚶 \(minutes):\(String(format: "%02d", secs))" : "🚶 \(secs)s"

        walkCountdownLabel?.text = text
    }

    // MARK: - Water Countdown

    func startWaterCountdown(interval: TimeInterval) {
        waterCountdownStartDate = Date()
        waterCountdownInterval = interval
        waterLastCountdownSecond = -1

        if waterCountdownContainer == nil {
            let container = SKNode()
            container.zPosition = 25
            addChild(container)
            waterCountdownContainer = container

            let label = SKLabelNode(text: "")
            label.fontName = "Helvetica-Bold"
            label.fontSize = 20
            label.fontColor = .white
            container.addChild(label)
            waterCountdownLabel = label
        }

        waterCountdownContainer?.isHidden = false
        waterCountdownContainer?.position = CGPoint(x: size.width / 2, y: size.height - 50)
        updateWaterCountdown()
    }

    func clearWaterCountdown() {
        waterCountdownContainer?.isHidden = true
        waterCountdownLabel?.text = ""
        waterCountdownStartDate = nil
        waterLastCountdownSecond = -1
    }

    private func updateWaterCountdown() {
        guard let startDate = waterCountdownStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, waterCountdownInterval - elapsed)
        let seconds = Int(ceil(remaining))

        guard seconds != waterLastCountdownSecond else { return }
        waterLastCountdownSecond = seconds

        if seconds <= 0 {
            clearWaterCountdown()
            return
        }

        let minutes = seconds / 60
        let secs = seconds % 60
        let text = minutes > 0 ? "💧 \(minutes):\(String(format: "%02d", secs))" : "💧 \(secs)s"

        waterCountdownLabel?.text = text
    }

}
