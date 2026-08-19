import Foundation
import AppKit

/// 粘贴控制器 — 将历史条目写回剪贴板并模拟粘贴操作
final class PasteController {
    static let shared = PasteController()

    private init() {}

    /// 仅将内容写入剪贴板，不触发粘贴（窗口保持打开）
    func copyOnly(_ item: ClipboardItem) {
        // 暂停监听，避免记录自己的操作
        ClipboardMonitor.shared.suspend()

        NSPasteboard.general.clearContents()

        switch item.type {
        case .text:
            NSPasteboard.general.setString(
                item.textContent ?? "",
                forType: .string
            )
        case .image:
            if let path = item.imagePath,
               let image = NSImage(contentsOfFile: path) {
                NSPasteboard.general.writeObjects([image])
            }
        }

        // 恢复监听
        ClipboardMonitor.shared.resume()
    }

    /// 将条目内容粘贴到当前活动应用
    func paste(_ item: ClipboardItem) {
        // 1. 保存当前剪贴板内容（后续恢复用）
        let savedItems = NSPasteboard.general.readObjects(
            forClasses: [NSString.self, NSImage.self],
            options: nil
        )
        let savedChangeCount = NSPasteboard.general.changeCount

        // 2. 暂停监听，避免记录我们自己的粘贴操作
        ClipboardMonitor.shared.suspend()

        // 3. 将目标内容写入剪贴板
        NSPasteboard.general.clearContents()
        let pasteSuccess: Bool

        switch item.type {
        case .text:
            pasteSuccess = NSPasteboard.general.setString(
                item.textContent ?? "",
                forType: .string
            )
        case .image:
            if let path = item.imagePath,
               let image = NSImage(contentsOfFile: path) {
                pasteSuccess = NSPasteboard.general.writeObjects([image])
            } else {
                pasteSuccess = false
            }
        }

        guard pasteSuccess else {
            ClipboardMonitor.shared.resume()
            return
        }

        // 4. 模拟 Cmd+V 粘贴到当前活动应用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.simulatePasteShortcut()

            // 5. 延迟恢复原始剪贴板内容
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.restorePasteboard(
                    items: savedItems,
                    changeCount: savedChangeCount
                )
                ClipboardMonitor.shared.resume()
            }
        }

        // 6. 收起 Popover
        DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.closePopover()
            }
        }
    }

    // MARK: - 模拟按键

    private func simulatePasteShortcut() {
        let source = CGEventSource(stateID: .combinedSessionState)

        // 按下 Cmd+V
        let cmdVDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0x09, // V key
            keyDown: true
        )
        cmdVDown?.flags = .maskCommand

        // 松开 Cmd+V
        let cmdVUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: 0x09,
            keyDown: false
        )
        cmdVUp?.flags = .maskCommand

        cmdVDown?.post(tap: .cghidEventTap)
        cmdVUp?.post(tap: .cghidEventTap)
    }

    // MARK: - 恢复剪贴板

    private func restorePasteboard(items: [Any]?, changeCount: Int) {
        // 简单策略：清空剪贴板，让下次正常复制重新填充
        // 这样可以避免恢复过程中的二次触发问题
        NSPasteboard.general.clearContents()
    }
}
