import SwiftUI
import AppKit

/// 管理条目检视窗口的创建和销毁
final class DetailWindowController {
    static let shared = DetailWindowController()

    private var window: NSWindow?

    private init() {}

    /// 为指定条目打开检视窗口（关闭已有窗口，创建新窗口）
    func show(item: ClipboardItem) {
        // 关闭旧窗口
        window?.close()

        let detailView = DetailView(item: item) { [weak self] in
            self?.window?.close()
        }

        let hostingView = NSHostingView(rootView: detailView)
        hostingView.frame.size = hostingView.fittingSize

        let window = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: hostingView.fittingSize.width,
                height: hostingView.fittingSize.height
            ),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "检视 — 历史剪贴板"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = WindowDelegate.shared

        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}

/// 窗口关闭时清理引用
private final class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()

    func windowWillClose(_ notification: Notification) {
        // 确保窗口释放
        if let window = notification.object as? NSWindow {
            window.contentView = nil
        }
    }
}
