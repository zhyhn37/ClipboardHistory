import SwiftUI

@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

/// AppDelegate — 管理生命周期：菜单栏、剪贴板监听、启动清理
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let monitor = ClipboardMonitor.shared
    private let dataStore = DataStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 清理旧版「存储时长」设置残留（固定保留 3 天，不再读取该设置）
        UserDefaults.standard.removeObject(forKey: "retentionDays")

        // 启动时清理过期数据
        dataStore.cleanExpired()

        // 启动剪贴板监听
        monitor.start()

        // 显示菜单栏
        menuBarController = MenuBarController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    /// 收起 Popover（粘贴操作后调用）
    func closePopover() {
        menuBarController?.closePopover()
    }
}
