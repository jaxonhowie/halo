import Cocoa
import SpriteKit
import WebKit

// MARK: - Debug Logger

private let debugLogPath = NSHomeDirectory() + "/halo_debug.log"

func debugLog(_ message: String) {
    NSLog("%@", message)
    let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
    guard let data = "[\(ts)] \(message)\n".data(using: .utf8) else { return }
    if let fh = FileHandle(forWritingAtPath: debugLogPath) {
        fh.seekToEndOfFile(); fh.write(data); fh.closeFile()
    } else {
        FileManager.default.createFile(atPath: debugLogPath, contents: data)
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
    private var pendingSingleClick: DispatchWorkItem?

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
            pendingSingleClick?.cancel()
            pendingSingleClick = nil
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
            if event.clickCount >= 2 {
                pendingSingleClick?.cancel()
                pendingSingleClick = nil
                catScene.handlePet()
            } else {
                let work = DispatchWorkItem { [weak self] in
                    self?.catScene.handleTap()
                    self?.pendingSingleClick = nil
                }
                pendingSingleClick = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
            }
        }
        isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(event)
    }

    private func showContextMenu(_ event: NSEvent) {
        let menu = NSMenu()
        for (title, action) in [("待机", #selector(setIdle)), ("走动", #selector(setWalk)),
                                 ("睡觉", #selector(setSleep)), ("想吃鱼", #selector(setWantFish))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        let statsItem = NSMenuItem(title: "查看统计", action: #selector(showStats), keyEquivalent: "")
        statsItem.target = self
        menu.addItem(statsItem)
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

    @objc func showStats() {
        (NSApp.delegate as? AppDelegate)?.showStatsPanel()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Stats Panel

class StatsPanel: NSPanel, WKNavigationDelegate {
    private var webView: WKWebView!
    private var refreshTimer: Timer?
    private var isPageLoaded = false

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 440),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        title = "今日统计"
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .windowBackgroundColor
        hidesOnDeactivate = false
        isMovableByWindowBackground = true

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 420, height: 440), configuration: config)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        self.contentView = webView
        loadHTML()
    }

    private func loadHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
                background: rgba(30,30,30,0.95);
                color: #f0f0f0;
                padding: 16px;
                overflow: hidden;
            }
            h2 { font-size: 15px; margin-bottom: 12px; color: #aaa; font-weight: 500; }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 16px;
            }
            td {
                padding: 8px 12px;
                font-size: 14px;
                border-bottom: 1px solid rgba(255,255,255,0.08);
            }
            td:first-child { color: #aaa; width: 120px; }
            td:last-child { text-align: right; font-weight: 600; color: #fff; }
            #chart { width: 100%; height: 260px; }
        </style>
        </head>
        <body>
            <h2>今日统计</h2>
            <table>
                <tr><td>💧 喝水</td><td id="water">0 次</td></tr>
                <tr><td>🚶 走动</td><td id="walk">0 次</td></tr>
                <tr><td>💻 工作时长</td><td id="work">0 分钟</td></tr>
            </table>
            <div id="chart"></div>
            <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
            <script>
                var chart = echarts.init(document.getElementById('chart'), 'dark');
                var option = {
                    backgroundColor: 'transparent',
                    grid: { left: 50, right: 20, top: 20, bottom: 30 },
                    xAxis: {
                        type: 'category',
                        data: ['喝水', '走动', '工作(小时)'],
                        axisLine: { lineStyle: { color: '#555' } },
                        axisLabel: { color: '#aaa', fontSize: 12 }
                    },
                    yAxis: {
                        type: 'value',
                        minInterval: 0.5,
                        axisLine: { show: false },
                        splitLine: { lineStyle: { color: 'rgba(255,255,255,0.06)' } },
                        axisLabel: { color: '#aaa', fontSize: 11 }
                    },
                    series: [{
                        type: 'bar',
                        data: [0, 0, 0],
                        barWidth: 36,
                        itemStyle: {
                            borderRadius: [6, 6, 0, 0],
                            color: function(params) {
                                var colors = ['#4FC3F7', '#81C784', '#FFB74D'];
                                return colors[params.dataIndex];
                            }
                        },
                        label: {
                            show: true,
                            position: 'top',
                            color: '#ccc',
                            fontSize: 12
                        }
                    }]
                };
                chart.setOption(option);

                function updateData(water, walk, workMinutes) {
                    document.getElementById('water').textContent = water + ' 次';
                    document.getElementById('walk').textContent = walk + ' 次';
                    var h = Math.floor(workMinutes / 60);
                    var m = workMinutes % 60;
                    document.getElementById('work').textContent = h > 0 ? h + ' 小时 ' + m + ' 分钟' : m + ' 分钟';
                    chart.setOption({
                        series: [{ data: [water, walk, Math.round(workMinutes / 60 * 10) / 10] }]
                    });
                }
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isPageLoaded = true
        refresh()
    }

    func refresh() {
        guard isPageLoaded else { return }
        let appDelegate = NSApp.delegate as? AppDelegate
        let water = appDelegate?.waterCount ?? 0
        let walk = appDelegate?.walkCount ?? 0
        let totalSeconds = appDelegate?.todayWorkSeconds ?? 0
        let workMinutes = totalSeconds / 60
        webView.evaluateJavaScript("updateData(\(water), \(walk), \(workMinutes))")
    }

    func showPanel(relativeTo parentWindow: NSWindow) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        makeKeyAndOrderFront(nil)

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    override func close() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        isPageLoaded = false
        super.close()
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
    // Session timer
    var sessionStartDate: Date?
    private var lastKeyboardActivity: Date?
    private var sessionIdleTimer: Timer?
    private let sessionIdleTimeout: TimeInterval = 10 * 60
    // Stats panel
    var statsPanel: StatsPanel?

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

    var todayWorkSeconds: Int {
        let defaults = UserDefaults.standard
        let savedDate = defaults.string(forKey: "workDate") ?? ""
        let today = Self.todayString()
        if savedDate != today {
            defaults.set(today, forKey: "workDate")
            defaults.set(0, forKey: "todayWorkSeconds")
        }
        let saved = defaults.integer(forKey: "todayWorkSeconds")
        // Include current running session time
        if let start = sessionStartDate, let lastActive = lastKeyboardActivity {
            return saved + Int(lastActive.timeIntervalSince(start))
        }
        return saved
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func todayString() -> String {
        dateFormatter.string(from: Date())
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let windowSize = NSSize(width: 208, height: 208)

        // Restore saved window position or use default
        let windowOrigin: NSPoint
        let defaults = UserDefaults.standard
        let savedX = defaults.double(forKey: "windowX")
        let savedY = defaults.double(forKey: "windowY")
        let hasSavedPosition = defaults.object(forKey: "windowX") != nil
        let savedPoint = NSPoint(x: savedX, y: savedY)
        if hasSavedPosition && NScreenContainsPoint(savedPoint, windowSize: windowSize) {
            windowOrigin = savedPoint
        } else {
            let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            windowOrigin = NSPoint(
                x: screenFrame.maxX - windowSize.width - 50,
                y: screenFrame.minY + 100
            )
        }

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

    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
        endSession()
    }

    func applicationWillResignActive(_ notification: Notification) {
        saveWindowPosition()
    }

    private func saveWindowPosition() {
        guard let origin = window?.frame.origin else { return }
        let defaults = UserDefaults.standard
        defaults.set(Double(origin.x), forKey: "windowX")
        defaults.set(Double(origin.y), forKey: "windowY")
    }

    private func NScreenContainsPoint(_ point: NSPoint, windowSize: NSSize) -> Bool {
        for screen in NSScreen.screens {
            let visible = screen.visibleFrame
            let rect = NSRect(origin: point, size: windowSize)
            if visible.intersects(rect) {
                return true
            }
        }
        return false
    }

    // MARK: - Keyboard Monitor

    func startKeyboardMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            // Ignore keyboard activity in stats panel
            if self.statsPanel?.isKeyWindow == true { return }

            // Session timer: track keyboard activity
            self.lastKeyboardActivity = Date()
            if self.sessionStartDate == nil {
                self.sessionStartDate = Date()
            }
            self.sessionIdleTimer?.invalidate()
            self.sessionIdleTimer = Timer.scheduledTimer(withTimeInterval: self.sessionIdleTimeout, repeats: false) { [weak self] _ in
                self?.endSession()
            }

            // Walk reminder
            if !self.isWalkReminding, self.walkTimer == nil {
                self.walkTimer = Timer.scheduledTimer(withTimeInterval: self.walkReminderInterval, repeats: false) { [weak self] _ in
                    self?.walkTimer = nil
                    self?.triggerWalkReminder()
                }
                self.petView.catScene.startWalkCountdown(interval: self.walkReminderInterval)
            }
            // Water reminder
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

    // MARK: - Session Timer

    private func endSession() {
        if let start = sessionStartDate, let lastActive = lastKeyboardActivity {
            let elapsed = Int(lastActive.timeIntervalSince(start))
            let defaults = UserDefaults.standard
            let today = Self.todayString()
            let existing = (defaults.string(forKey: "workDate") ?? "") == today ? defaults.integer(forKey: "todayWorkSeconds") : 0
            defaults.set(today, forKey: "workDate")
            defaults.set(existing + elapsed, forKey: "todayWorkSeconds")
        }
        sessionStartDate = nil
        sessionIdleTimer = nil
    }

    // MARK: - Stats

    func showStatsPanel() {
        if statsPanel == nil {
            statsPanel = StatsPanel()
        }
        statsPanel?.refresh()
        statsPanel?.showPanel(relativeTo: window)
    }

    private func showAlert(message: String, info: String, button: String) {
        savedPosition = window.frame.origin
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(x: sf.midX - window.frame.width / 2, y: sf.midY - window.frame.height / 2))
        }
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.addButton(withTitle: button)
        alert.alertStyle = .informational
        alert.window.level = .floating
        if let url = Bundle.module.url(forResource: "Halo", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) { alert.icon = icon }
        alert.runModal()
        window.setFrameOrigin(savedPosition)
    }

    func triggerWaterReminder() {
        guard !isWaterReminding else { return }
        isWaterReminding = true
        waterTimer?.invalidate(); waterTimer = nil
        petView.catScene.clearWaterCountdown()
        showAlert(message: "该喝水了哟~", info: "记得休息一下，保持健康！", button: "喝过啦")
        waterCount += 1
        isWaterReminding = false
    }

    func triggerWalkReminder() {
        guard !isWalkReminding else { return }
        isWalkReminding = true
        walkTimer?.invalidate(); walkTimer = nil
        petView.catScene.clearWalkCountdown()
        showAlert(message: "该起身走动啦~", info: "久坐伤身，起来活动一下吧！", button: "走过了")
        walkCount += 1
        isWalkReminding = false
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
