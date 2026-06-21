import Foundation

/// 剪贴板条目类型
enum ItemType: String, Codable {
    case text
    case image
}

/// 剪贴板历史条目模型
struct ClipboardItem: Identifiable, Codable, Equatable {
    var id: Int64
    var type: ItemType
    var textContent: String?
    var imagePath: String?
    var timestamp: Date
    var isPinned: Bool
    var textPreview: String?

    /// 创建一个文字类型条目
    static func textItem(
        id: Int64 = 0,
        content: String,
        timestamp: Date = Date(),
        isPinned: Bool = false
    ) -> ClipboardItem {
        let preview = String(content.prefix(100))
            .replacingOccurrences(of: "\n", with: " ")
        return ClipboardItem(
            id: id,
            type: .text,
            textContent: content,
            imagePath: nil,
            timestamp: timestamp,
            isPinned: isPinned,
            textPreview: preview
        )
    }

    /// 创建一个图片类型条目
    static func imageItem(
        id: Int64 = 0,
        imagePath: String,
        timestamp: Date = Date(),
        isPinned: Bool = false
    ) -> ClipboardItem {
        return ClipboardItem(
            id: id,
            type: .image,
            textContent: nil,
            imagePath: imagePath,
            timestamp: timestamp,
            isPinned: isPinned,
            textPreview: "[图片]"
        )
    }
}
