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

        let count = (NSApp.delegate as? AppDelegate)?.waterCount ?? 0
        let countItem = NSMenuItem(title: "今日喝水: \(count) 次", action: nil, keyEquivalent: "")
        countItem.isEnabled = false
        menu.addItem(countItem)

        let remindItem = NSMenuItem(title: "提醒喝水", action: #selector(triggerRemind), keyEquivalent: "r")
        remindItem.target = self
        menu.addItem(remindItem)

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

    @objc func triggerRemind() {
        (NSApp.delegate as? AppDelegate)?.triggerReminder()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PetWindow!
    var petView: PetView!
    private var workTimer: Timer?
    private var savedPosition: NSPoint = .zero
    private let reminderInterval: TimeInterval = 15 * 60
    private var isReminding = false
    private var keyMonitor: Any?

    var waterCount: Int {
        get {
            let defaults = UserDefaults.standard
            let savedDate = defaults.string(forKey: "waterDate") ?? ""
            let today = Self.todayString()
            if savedDate != today {
                defaults.set(today, forKey: "waterDate")
                defaults.set(0, forKey: "waterCount")
            }
            return defaults.integer(forKey: "waterCount")
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(Self.todayString(), forKey: "waterDate")
            defaults.set(newValue, forKey: "waterCount")
        }
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        let windowSize = NSSize(width: 208, height: 208)
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

        startKeyboardMonitor()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Water Reminder

    func startKeyboardMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            guard let self = self, !self.isReminding, self.workTimer == nil else { return }
            self.workTimer = Timer.scheduledTimer(withTimeInterval: self.reminderInterval, repeats: false) { [weak self] _ in
                self?.workTimer = nil
                self?.triggerReminder()
            }
            self.petView.catScene.startCountdown(interval: self.reminderInterval)
        }
        print("✓ 键盘监控已启动，\(Int(reminderInterval / 60)) 分钟后提醒喝水")
    }

    func triggerReminder() {
        guard !isReminding else { return }
        isReminding = true
        workTimer?.invalidate()
        workTimer = nil
        petView.catScene.clearCountdown()

        savedPosition = window.frame.origin

        // 移动到屏幕中央
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let centerX = screenFrame.midX - window.frame.width / 2
            let centerY = screenFrame.midY - window.frame.height / 2
            window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
        }

        // 弹出确认框
        let alert = NSAlert()
        alert.messageText = "该喝水了哟~"
        alert.informativeText = "记得休息一下，保持健康！"
        alert.addButton(withTitle: "喝过啦")
        alert.alertStyle = .informational
        alert.window.level = .floating
        if let iconURL = Bundle.module.url(forResource: "Halo", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            alert.icon = icon
        }

        alert.runModal()

        // 记录喝水
        waterCount += 1

        // 回到原位
        window.setFrameOrigin(savedPosition)

        // 清除状态，等待下次键盘输入重新开始
        isReminding = false
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
