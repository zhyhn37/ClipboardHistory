import Foundation
import AppKit
import CryptoKit

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

    // MARK: - 内容哈希

    /// 计算图片的稳定内容哈希（基于归一化像素，跨会话一致，用于重复合并判定）
    /// - Parameter image: 要哈希的图片
    /// - Returns: 64 位十六进制字符串，失败返回 nil
    func contentHash(of image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              cgImage.width > 0, cgImage.height > 0 else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // 超大图保护：像素缓冲超过 256MB 时降级为 TIFF 字节哈希（同样跨会话稳定）
        guard width * height * 4 <= 256 * 1024 * 1024 else {
            guard let tiffData = image.tiffRepresentation else { return nil }
            return Self.sha256Hex(Data(tiffData))
        }

        // 渲染到统一的 sRGB RGBA8 像素缓冲，保证同图不同编码格式哈希一致
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Self.sha256Hex(Data(pixels))
    }

    /// 计算数据的 SHA256 哈希，返回 64 位十六进制字符串
    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
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
