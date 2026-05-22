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
    private var zzzNodes: [SKLabelNode] = []
    private let walkRange: CGFloat = 36.0
    private let catDisplaySize = CGSize(width: 140, height: 140)
    private let idleMaxDisplaySize = CGSize(width: 144, height: 148)
    private let walkMaxDisplaySize = CGSize(width: 144, height: 148)
    private let sleepMaxDisplaySize = CGSize(width: 144, height: 148)
    private let wantFishMaxDisplaySize = CGSize(width: 144, height: 148)

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
        let texture = idleTextures.first ?? textureFromPixelData(SpriteData.idle0)
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

    private func applyWalkFacing() {
        // The walk sheet faces left; flip it when moving right.
        catNode.xScale = walkTextures.isEmpty ? direction : -direction
    }

    private func textureFromPixelData(_ data: [[Int]]) -> SKTexture {
        let width = data[0].count
        let height = data.count
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        for row in 0..<height {
            for col in 0..<width {
                let colorIndex = data[row][col]
                let color = CatColors.palette[colorIndex]
                let offset = (row * width + col) * 4
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                let rgbColor = color.usingColorSpace(.deviceRGB) ?? color
                rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                pixelData[offset]     = UInt8(r * 255)
                pixelData[offset + 1] = UInt8(g * 255)
                pixelData[offset + 2] = UInt8(b * 255)
                pixelData[offset + 3] = UInt8(a * 255)
            }
        }

        let provider = CGDataProvider(data: Data(pixelData) as CFData)!
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest
        return texture
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

        // Update ZZZ for sleep state
        if currentState == .sleep {
            updateZzz(currentTime)
        }
    }

    private func advanceFrame() {
        switch currentState {
        case .idle:
            let frames = idleTextures.isEmpty ? [textureFromPixelData(SpriteData.idle0)] : idleTextures
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = frames[currentFrame]
            catNode.size = idleDisplaySize(for: frames[currentFrame])
        case .walk:
            if !walkTextures.isEmpty {
                currentFrame = (currentFrame + 1) % walkTextures.count
                catNode.texture = walkTextures[currentFrame]
                catNode.size = walkDisplaySize(for: walkTextures[currentFrame])
                applyWalkFacing()
                return
            }
            let frames = SpriteData.walkFrames
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = textureFromPixelData(frames[currentFrame])
            catNode.size = catDisplaySize
        case .sleep:
            if !sleepTextures.isEmpty {
                currentFrame = (currentFrame + 1) % sleepTextures.count
                catNode.texture = sleepTextures[currentFrame]
                catNode.size = sleepDisplaySize(for: sleepTextures[currentFrame])
                return
            }
            let frames = SpriteData.sleepFrames
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = textureFromPixelData(frames[currentFrame])
            catNode.size = catDisplaySize
        case .wantFish:
            if !wantFishTextures.isEmpty {
                currentFrame = (currentFrame + 1) % wantFishTextures.count
                catNode.texture = wantFishTextures[currentFrame]
                catNode.size = wantFishDisplaySize(for: wantFishTextures[currentFrame])
                return
            }
            let frames = idleTextures.isEmpty ? [textureFromPixelData(SpriteData.idle0)] : idleTextures
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = frames[currentFrame]
            catNode.size = idleDisplaySize(for: frames[currentFrame])
        case .jump:
            let frames = SpriteData.jumpFrames
            currentFrame = (currentFrame + 1) % frames.count
            catNode.texture = textureFromPixelData(frames[currentFrame])
            catNode.size = catDisplaySize
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

        // Clear state-specific nodes
        clearZzz()
        removeMeow()

        switch newState {
        case .idle:
            let texture = idleTextures.first ?? textureFromPixelData(SpriteData.idle0)
            catNode.texture = texture
            catNode.size = idleDisplaySize(for: texture)
            catNode.xScale = 1
        case .walk:
            if let texture = walkTextures.first {
                catNode.texture = texture
                catNode.size = walkDisplaySize(for: texture)
            } else {
                let frames = SpriteData.walkFrames
                catNode.texture = textureFromPixelData(frames[0])
                catNode.size = catDisplaySize
            }
            applyWalkFacing()
        case .sleep:
            if let texture = sleepTextures.first {
                catNode.texture = texture
                catNode.size = sleepDisplaySize(for: texture)
            } else {
                let frames = SpriteData.sleepFrames
                catNode.texture = textureFromPixelData(frames[0])
                catNode.size = catDisplaySize
            }
            catNode.xScale = 1
        case .wantFish:
            if let texture = wantFishTextures.first {
                catNode.texture = texture
                catNode.size = wantFishDisplaySize(for: texture)
            } else {
                let texture = idleTextures.first ?? textureFromPixelData(SpriteData.idle0)
                catNode.texture = texture
                catNode.size = idleDisplaySize(for: texture)
            }
            catNode.xScale = 1
        case .jump:
            let frames = SpriteData.jumpFrames
            catNode.texture = textureFromPixelData(frames[0])
            catNode.size = catDisplaySize
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

    // MARK: - ZZZ Animation

    private func updateZzz(_ currentTime: TimeInterval) {
        guard sleepTextures.isEmpty else { return }
        // Spawn a new Z every 2 seconds
        if zzzNodes.isEmpty || (currentTime.truncatingRemainder(dividingBy: 2.0) < 0.02) {
            spawnZzz()
        }
    }

    private func spawnZzz() {
        guard zzzNodes.count < 3 else { return }
        let z = SKLabelNode(text: "Z")
        z.fontName = "Helvetica-Bold"
        z.fontSize = CGFloat.random(in: 10...16)
        z.fontColor = NSColor(hex: 0x87CEEB)?.withAlphaComponent(0.7)
        z.position = CGPoint(
            x: catNode.position.x + CGFloat.random(in: 15...30),
            y: catNode.position.y + 30
        )
        z.zPosition = 20
        addChild(z)
        zzzNodes.append(z)

        let moveUp = SKAction.moveBy(x: 5, y: 40, duration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let grow = SKAction.scale(to: 1.5, duration: 2.0)
        let group = SKAction.group([moveUp, fadeOut, grow])
        let remove = SKAction.removeFromParent()
        z.run(SKAction.sequence([group, remove])) { [weak self] in
            self?.zzzNodes.removeAll { $0 === z }
        }
    }

    private func clearZzz() {
        zzzNodes.forEach { $0.removeFromParent() }
        zzzNodes.removeAll()
    }
}
