import Cocoa
import SpriteKit

// MARK: - Transparent, Borderless, Always-on-Top Window

class PetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - SpriteKit View with Click/Drag Support

class PetView: SKView {
    var catScene: CatSpriteScene!
    private var isDragging = false
    private var dragStart: NSPoint = .zero
    private var windowDragStart: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        isDragging = false
        dragStart = location
        windowDragStart = window?.frame.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let dx = location.x - dragStart.x
        let dy = location.y - dragStart.y

        if !isDragging && (abs(dx) > 3 || abs(dy) > 3) {
            isDragging = true
        }

        if isDragging {
            let newOrigin = NSPoint(
                x: windowDragStart.x + dx,
                y: windowDragStart.y + dy
            )
            window?.setFrameOrigin(newOrigin)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !isDragging {
            // It was a tap, not a drag
            catScene.handleTap()
        }
        isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(event)
    }

    private func showContextMenu(_ event: NSEvent) {
        let menu = NSMenu()

        let idleItem = NSMenuItem(title: "待机", action: #selector(setIdle), keyEquivalent: "")
        idleItem.target = self
        menu.addItem(idleItem)

        let walkItem = NSMenuItem(title: "走动", action: #selector(setWalk), keyEquivalent: "")
        walkItem.target = self
        menu.addItem(walkItem)

        let sleepItem = NSMenuItem(title: "睡觉", action: #selector(setSleep), keyEquivalent: "")
        sleepItem.target = self
        menu.addItem(sleepItem)

        let wantFishItem = NSMenuItem(title: "想吃鱼", action: #selector(setWantFish), keyEquivalent: "")
        wantFishItem.target = self
        menu.addItem(wantFishItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc func setIdle() { catScene.setState(.idle) }
    @objc func setWalk() {
        catScene.setState(.walk)
    }
    @objc func setSleep() { catScene.setState(.sleep) }
    @objc func setWantFish() { catScene.setState(.wantFish) }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PetWindow!
    var petView: PetView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        let windowSize = NSSize(width: 160, height: 160)
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let windowOrigin = NSPoint(
            x: screenFrame.maxX - windowSize.width - 50,
            y: screenFrame.minY + 100
        )

        window = PetWindow(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = false

        // Create SpriteKit view
        petView = PetView(frame: NSRect(origin: .zero, size: windowSize))
        petView.allowsTransparency = true

        let scene = CatSpriteScene(size: windowSize)
        scene.scaleMode = .resizeFill
        petView.presentScene(scene)
        petView.catScene = scene

        window.contentView = petView
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
