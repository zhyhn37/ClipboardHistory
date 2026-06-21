import Foundation
import AppKit

/// 图片文件管理器 — 负责剪贴板图片的磁盘存储
final class ImageStorage {
    static let shared = ImageStorage()

    /// 图片存储目录
    private var imagesDir: URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }
        return appSupport.appendingPathComponent("ClipboardHistory/Images")
    }

    private init() {
        createImagesDirectory()
    }

    private func createImagesDirectory() {
        guard let dir = imagesDir else { return }
        do {
            try FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        } catch {
            print("❌ 图片目录创建失败: \(error)")
        }
    }

    // MARK: - 保存

    /// 保存图片到磁盘
    /// - Parameter image: 要保存的 NSImage
    /// - Returns: 文件的完整路径，失败返回 nil
    func saveImage(_ image: NSImage) -> String? {
        guard let dir = imagesDir else { return nil }

        let fileName = "\(UUID().uuidString).png"
        let filePath = dir.appendingPathComponent(fileName).path

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(
                using: .png,
                properties: [:]
              ) else {
            print("❌ 图片转换 PNG 失败")
            return nil
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: filePath))
            return filePath
        } catch {
            print("❌ 图片写入失败: \(error)")
            return nil
        }
    }

    // MARK: - 删除

    /// 删除指定路径的图片文件
    func deleteImage(at path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("⚠️ 图片删除失败: \(error)")
        }
    }

    // MARK: - 缩略图

    /// 从图片路径生成缩略图（用于卡片展示）
    /// - Parameter path: 图片文件路径
    /// - Parameter maxSize: 缩略图最大边长
    /// - Returns: 缩略图 NSImage
    func thumbnail(from path: String, maxSize: CGFloat = 48) -> NSImage? {
        guard let image = NSImage(contentsOfFile: path) else { return nil }

        let aspectRatio = image.size.width / image.size.height
        var newSize = NSSize(width: maxSize, height: maxSize)
        if aspectRatio > 1 {
            newSize.height = maxSize / aspectRatio
        } else {
            newSize.width = maxSize * aspectRatio
        }

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        return thumbnail
    }
}
