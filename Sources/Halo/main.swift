import Cocoa
import SpriteKit

// MARK: - Debug Logger

func debugLog(_ message: String) {
    NSLog("%@", message)
    let logPath = NSHomeDirectory() + "/halo_debug.log"
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    let line = "[\(timestamp)] \(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logPath) {
            if let fh = FileHandle(forWritingAtPath: logPath) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: logPath, contents: data)
        }
    }
}

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

        let waterCount = (NSApp.delegate as? AppDelegate)?.waterCount ?? 0
        let waterCountItem = NSMenuItem(title: "今日喝水: \(waterCount) 次", action: nil, keyEquivalent: "")
        waterCountItem.isEnabled = false
        menu.addItem(waterCountItem)

        let waterRemindItem = NSMenuItem(title: "提醒喝水", action: #selector(triggerWaterRemind), keyEquivalent: "r")
        waterRemindItem.target = self
        menu.addItem(waterRemindItem)

        let walkCount = (NSApp.delegate as? AppDelegate)?.walkCount ?? 0
        let walkCountItem = NSMenuItem(title: "今日走动: \(walkCount) 次", action: nil, keyEquivalent: "")
        walkCountItem.isEnabled = false
        menu.addItem(walkCountItem)

        let walkRemindItem = NSMenuItem(title: "提醒走动", action: #selector(triggerWalkRemind), keyEquivalent: "w")
        walkRemindItem.target = self
        menu.addItem(walkRemindItem)

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

    @objc func triggerWaterRemind() {
        (NSApp.delegate as? AppDelegate)?.triggerWaterReminder()
    }

    @objc func triggerWalkRemind() {
        (NSApp.delegate as? AppDelegate)?.triggerWalkReminder()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: PetWindow!
    var petView: PetView!
    private var waterTimer: Timer?
    private var walkTimer: Timer?
    private var savedPosition: NSPoint = .zero
    private let waterReminderInterval: TimeInterval = 15 * 60
    private let walkReminderInterval: TimeInterval = 60 * 60
    private var isWaterReminding = false
    private var isWalkReminding = false
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

    var walkCount: Int {
        get {
            let defaults = UserDefaults.standard
            let savedDate = defaults.string(forKey: "walkDate") ?? ""
            let today = Self.todayString()
            if savedDate != today {
                defaults.set(today, forKey: "walkDate")
                defaults.set(0, forKey: "walkCount")
            }
            return defaults.integer(forKey: "walkCount")
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(Self.todayString(), forKey: "walkDate")
            defaults.set(newValue, forKey: "walkCount")
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

        checkAccessibilityPermission()
        startKeyboardMonitor()
    }

    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        debugLog("Halo: 辅助功能权限状态 = \(trusted)")
        if !trusted {
            debugLog("Halo: 请前往 系统设置 → 隐私与安全性 → 辅助功能，添加 Halo 应用")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Keyboard Monitor

    func startKeyboardMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            guard let self = self else { return }
            if !self.isWalkReminding, self.walkTimer == nil {
                self.walkTimer = Timer.scheduledTimer(withTimeInterval: self.walkReminderInterval, repeats: false) { [weak self] _ in
                    self?.walkTimer = nil
                    self?.triggerWalkReminder()
                }
                self.petView.catScene.startWalkCountdown(interval: self.walkReminderInterval)
            }
            if !self.isWaterReminding, self.waterTimer == nil {
                self.waterTimer = Timer.scheduledTimer(withTimeInterval: self.waterReminderInterval, repeats: false) { [weak self] _ in
                    self?.waterTimer = nil
                    self?.triggerWaterReminder()
                }
                self.petView.catScene.startWaterCountdown(interval: self.waterReminderInterval)
            }
        }
        debugLog("Halo: 键盘监控已启动，\(Int(waterReminderInterval / 60)) 分钟后提醒喝水，\(Int(walkReminderInterval / 60)) 分钟后提醒走动")
    }

    func triggerWaterReminder() {
        guard !isWaterReminding else { return }
        isWaterReminding = true
        waterTimer?.invalidate()
        waterTimer = nil
        petView.catScene.clearWaterCountdown()

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
        isWaterReminding = false
    }

    func triggerWalkReminder() {
        guard !isWalkReminding else { return }
        isWalkReminding = true
        walkTimer?.invalidate()
        walkTimer = nil
        petView.catScene.clearWalkCountdown()

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
        alert.messageText = "该起身走动啦~"
        alert.informativeText = "久坐伤身，起来活动一下吧！"
        alert.addButton(withTitle: "走过了")
        alert.alertStyle = .informational
        alert.window.level = .floating
        if let iconURL = Bundle.module.url(forResource: "Halo", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            alert.icon = icon
        }

        alert.runModal()

        // 记录走动
        walkCount += 1

        // 回到原位
        window.setFrameOrigin(savedPosition)

        // 清除状态，等待下次键盘输入重新开始
        isWalkReminding = false
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
