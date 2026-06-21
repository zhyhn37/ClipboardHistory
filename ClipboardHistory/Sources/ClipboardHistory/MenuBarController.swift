import SwiftUI
import AppKit
import ServiceManagement

/// 菜单栏控制器 — 管理状态栏图标、弹出窗口、快捷键和右键菜单
final class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private var keyboardMonitor: Any?

    override init() {
        super.init()
        setupMenuBar()
        setupGlobalShortcut()
        setupAutoLaunch()
    }

    deinit {
        removeGlobalShortcut()
    }

    // MARK: - 菜单栏设置

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "clipboard",
                accessibilityDescription: "历史剪贴板"
            )
            button.target = self
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    // MARK: - Popover 创建（每次按需创建，避免 ViewBridge 持久化问题）

    private func createPopover() -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = true

        // 每次创建新的 ContentView，确保数据刷新
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
        )
        return popover
    }

    // MARK: - 交互

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        // 检测右键
        if let event = NSApp.currentEvent,
           event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if let popover = popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    /// 显示 Popover
    func showPopover() {
        guard let button = statusItem.button else { return }

        // 每次重新创建 Popover（避免 ViewBridge 缓存崩溃）
        if popover != nil {
            popover?.close()
            popover = nil
        }

        popover = createPopover()

        popover?.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
    }

    /// 收起 Popover
    func closePopover() {
        popover?.close()
        popover = nil
    }

    // MARK: - 右键菜单

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "偏好设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "退出历史剪贴板",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
        menu.delegate = self

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        closePopover()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - 全局快捷键

    private func setupGlobalShortcut() {
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == 9 { // V key
                DispatchQueue.main.async {
                    self?.showPopover()
                }
            }
        }
    }

    private func removeGlobalShortcut() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }

    // MARK: - 开机启动

    private func setupAutoLaunch() {
        guard #available(macOS 13.0, *) else { return }
        if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
            UserDefaults.standard.set(true, forKey: "launchAtLogin")
        }
    }

    static func updateAutoLaunch(enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("⚠️ 开机启动设置失败: \(error)")
        }
    }
}

// MARK: - NSMenuDelegate

extension MenuBarController {
    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}
