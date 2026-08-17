import Foundation
import AppKit

/// 剪贴板监听器 — 定时轮询系统剪贴板，自动记录新内容
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastTextContent: String?
    private var lastImageHash: String?

    private let dataStore = DataStore.shared
    private let imageStorage = ImageStorage.shared

    /// 轮询间隔（秒）
    private let pollingInterval: TimeInterval = 0.5

    /// 暂停标志：粘贴操作期间暂停监听，避免循环记录
    private var isSuspended = false

    private init() {}

    // MARK: - 启停

    /// 开始监听剪贴板
    func start() {
        stop()

        // 记录初始 changeCount，避免启动时误记录
        lastChangeCount = NSPasteboard.general.changeCount

        timer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkPasteboard()
        }

        // 允许 Timer 在 RunLoop 常用模式下也触发
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }

        print("👂 剪贴板监听已启动 (间隔 \(pollingInterval)s)")
    }

    /// 停止监听
    func stop() {
        timer?.invalidate()
        timer = nil
        print("🔇 剪贴板监听已停止")
    }

    /// 暂停监听（粘贴操作期间调用）
    func suspend() {
        isSuspended = true
    }

    /// 恢复监听
    func resume() {
        isSuspended = false
        // 更新 changeCount，避免恢复后误触发
        lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: - 剪贴板检测

    private func checkPasteboard() {
        // 暂停期间不处理剪贴板变化
        guard !isSuspended else { return }

        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        // changeCount 没变，跳过
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // 尝试读取文字
        if let text = pasteboard.string(forType: .string),
           !text.isEmpty {
            handleText(text)
            return
        }

        // 尝试读取图片
        if let image = pasteboard.readObjects(
            forClasses: [NSImage.self],
            options: nil
        )?.first as? NSImage {
            handleImage(image)
            return
        }
    }

    // MARK: - 文字处理

    private func handleText(_ text: String) {
        // 连续去重快速路径：与上一条文字内容相同则跳过
        guard text != lastTextContent else { return }
        lastTextContent = text
        lastImageHash = nil

        // 插入或合并：任意历史重复内容合并为一条，时间戳刷新到最新
        dataStore.insertOrMergeText(text)

        // 清理过期数据
        dataStore.cleanExpired()
    }

    // MARK: - 图片处理

    private func handleImage(_ image: NSImage) {
        // 稳定像素哈希（跨会话一致，用于合并判定与连续去重）
        guard let hash = imageStorage.contentHash(of: image) else {
            print("❌ 图片哈希计算失败")
            return
        }

        // 连续去重快速路径：与上一张图片相同则跳过
        guard hash != lastImageHash else { return }

        // 插入或合并：命中时只刷新时间戳，不重复写盘
        if dataStore.insertOrMergeImage(image, contentHash: hash) {
            lastImageHash = hash
            lastTextContent = nil
        }

        // 清理过期数据
        dataStore.cleanExpired()
    }
}
