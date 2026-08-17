import Foundation
import Combine
import SQLite3
import AppKit

/// SQLITE_TRANSIENT: 告诉 SQLite 复制字符串内容（Swift 的临时 C 字符串指针不稳定）
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// 数据存储层 — 基于系统内置 SQLite3 的本地持久化
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var items: [ClipboardItem] = []

    /// 是否为空
    var isEmpty: Bool { items.isEmpty }

    private var db: OpaquePointer?

    // MARK: - 初始化

    private init() {
        setupDatabase()
        loadItems()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - 数据库初始化

    private func setupDatabase() {
        do {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbDir = appSupport.appendingPathComponent("ClipboardHistory")
            try FileManager.default.createDirectory(
                at: dbDir,
                withIntermediateDirectories: true
            )
            let dbPath = dbDir.appendingPathComponent("history.sqlite").path

            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                print("❌ 数据库打开失败")
                return
            }

            let createSQL = """
                CREATE TABLE IF NOT EXISTS clipboard_item (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    type TEXT NOT NULL,
                    text_content TEXT,
                    image_path TEXT,
                    timestamp REAL NOT NULL,
                    is_pinned INTEGER DEFAULT 0,
                    text_preview TEXT,
                    content_hash TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_timestamp
                    ON clipboard_item(timestamp DESC);
                CREATE INDEX IF NOT EXISTS idx_pinned
                    ON clipboard_item(is_pinned);
            """

            var errMsg: UnsafeMutablePointer<CChar>?
            if sqlite3_exec(db, createSQL, nil, nil, &errMsg) != SQLITE_OK {
                let msg = errMsg.map { String(cString: $0) } ?? ""
                print("❌ 建表失败: \(msg)")
                sqlite3_free(errMsg)
            }

            // 轻量迁移：老版本数据库补列 + 建合并查询索引
            migrateIfNeeded()
        } catch {
            print("❌ 数据库初始化失败: \(error)")
        }
    }

    // MARK: - 数据库迁移

    /// 轻量迁移：老版本数据库补列 + 建合并查询索引（幂等，可重复执行）
    private func migrateIfNeeded() {
        if !columnExists("content_hash") {
            exec("ALTER TABLE clipboard_item ADD COLUMN content_hash TEXT")
            print("🛠️ 数据库迁移：新增 content_hash 列")
        }
        exec("CREATE INDEX IF NOT EXISTS idx_content_hash ON clipboard_item(content_hash)")
        exec("CREATE INDEX IF NOT EXISTS idx_text_content ON clipboard_item(text_content)")
    }

    /// 检查表中是否存在指定列
    private func columnExists(_ name: String) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(clipboard_item)", -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            // PRAGMA table_info 第 2 列为列名
            if let cName = sqlite3_column_text(statement, 1),
               String(cString: cName) == name {
                return true
            }
        }
        return false
    }

    /// 执行无绑定参数的单条 SQL（迁移用）
    private func exec(_ sql: String) {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? ""
            print("❌ SQL 执行失败: \(msg)")
            sqlite3_free(errMsg)
        }
    }

    // MARK: - 数据加载

    /// 从数据库加载全部条目（置顶优先，时间降序）
    /// 自动将 UI 更新分发到主线程
    func loadItems() {
        let results = loadItemsFromDB()
        if Thread.isMainThread {
            items = results
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.items = results
            }
        }
    }

    private func loadItemsFromDB() -> [ClipboardItem] {
        let sql = """
            SELECT id, type, text_content, image_path, timestamp, is_pinned, text_preview, content_hash
            FROM clipboard_item
            ORDER BY is_pinned DESC, timestamp DESC
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("❌ 查询准备失败")
            return []
        }
        defer { sqlite3_finalize(statement) }

        var results: [ClipboardItem] = []

        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let typeStr = String(cString: sqlite3_column_text(statement, 1))
            let type = ItemType(rawValue: typeStr) ?? .text

            var textContent: String?
            if let ptr = sqlite3_column_text(statement, 2) {
                textContent = String(cString: ptr)
            }

            var imagePath: String?
            if let ptr = sqlite3_column_text(statement, 3) {
                imagePath = String(cString: ptr)
            }

            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            let isPinned = sqlite3_column_int(statement, 5) != 0

            var textPreview: String?
            if let ptr = sqlite3_column_text(statement, 6) {
                textPreview = String(cString: ptr)
            }

            var contentHash: String?
            if let ptr = sqlite3_column_text(statement, 7) {
                contentHash = String(cString: ptr)
            }

            let item = ClipboardItem(
                id: id,
                type: type,
                textContent: textContent,
                imagePath: imagePath,
                timestamp: timestamp,
                isPinned: isPinned,
                textPreview: textPreview,
                contentHash: contentHash
            )
            results.append(item)
        }

        return results
    }

    // MARK: - CRUD

    /// 插入一条新记录
    func insertItem(_ item: ClipboardItem) {
        let sql = """
            INSERT INTO clipboard_item (type, text_content, image_path, timestamp, is_pinned, text_preview, content_hash)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        let typeStr = item.type.rawValue
        sqlite3_bind_text(statement, 1, typeStr, -1, SQLITE_TRANSIENT)

        if let text = item.textContent {
            sqlite3_bind_text(statement, 2, text, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 2)
        }

        if let path = item.imagePath {
            sqlite3_bind_text(statement, 3, path, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 3)
        }

        sqlite3_bind_double(statement, 4, item.timestamp.timeIntervalSince1970)
        sqlite3_bind_int(statement, 5, item.isPinned ? 1 : 0)

        if let preview = item.textPreview {
            sqlite3_bind_text(statement, 6, preview, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 6)
        }

        if let hash = item.contentHash {
            sqlite3_bind_text(statement, 7, hash, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 7)
        }

        if sqlite3_step(statement) != SQLITE_DONE {
            print("❌ 插入失败")
        }

        loadItems()
    }

    /// 删除指定记录（同时清理关联的图片文件）
    func deleteItem(id: Int64) {
        // 如果是图片类型，先获取路径并删除文件
        if let item = items.first(where: { $0.id == id }),
           item.type == .image,
           let path = item.imagePath {
            ImageStorage.shared.deleteImage(at: path)
        }

        let sql = "DELETE FROM clipboard_item WHERE id = ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, id)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("❌ 删除失败")
        }

        loadItems()
    }

    /// 切换置顶状态
    func togglePin(id: Int64) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        let newValue = item.isPinned ? 0 : 1

        let sql = "UPDATE clipboard_item SET is_pinned = ? WHERE id = ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(newValue))
        sqlite3_bind_int64(statement, 2, id)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("❌ 置顶切换失败")
        }

        loadItems()
    }

    // MARK: - 合并插入

    /// 插入或合并文字条目：内容已存在时仅刷新时间戳（跳到列表顶部，保留置顶状态）
    func insertOrMergeText(_ text: String) {
        let now = Date().timeIntervalSince1970
        if let existingID = findTextID(text) {
            updateTimestamp(id: existingID, timestamp: now)
            print("🔁 文字重复，合并到条目 #\(existingID)")
        } else {
            insertItem(ClipboardItem.textItem(content: text))
        }
    }

    /// 查找内容相同的文字条目 ID（取最新一条）
    private func findTextID(_ text: String) -> Int64? {
        let sql = """
            SELECT id FROM clipboard_item
            WHERE type = 'text' AND text_content = ?
            ORDER BY timestamp DESC LIMIT 1
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, text, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return sqlite3_column_int64(statement, 0)
    }

    /// 插入或合并图片条目：哈希命中时仅刷新时间戳，不重复写盘
    /// - Parameter image: 要保存的图片（未命中时写入磁盘）
    /// - Parameter contentHash: 图片内容哈希
    /// - Returns: 是否成功记录
    @discardableResult
    func insertOrMergeImage(_ image: NSImage, contentHash: String) -> Bool {
        let now = Date().timeIntervalSince1970
        if let existingID = findImageID(hash: contentHash) {
            updateTimestamp(id: existingID, timestamp: now)
            print("🔁 图片重复，合并到条目 #\(existingID)")
            return true
        }

        guard let imagePath = ImageStorage.shared.saveImage(image) else {
            print("❌ 图片保存失败")
            return false
        }
        insertItem(ClipboardItem.imageItem(imagePath: imagePath, contentHash: contentHash))
        return true
    }

    /// 查找内容哈希相同的图片条目 ID（取最新一条）
    private func findImageID(hash: String) -> Int64? {
        let sql = """
            SELECT id FROM clipboard_item
            WHERE type = 'image' AND content_hash = ?
            ORDER BY timestamp DESC LIMIT 1
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, hash, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return sqlite3_column_int64(statement, 0)
    }

    /// 仅刷新条目的时间戳（合并用），不动置顶与预览
    private func updateTimestamp(id: Int64, timestamp: TimeInterval) {
        let sql = "UPDATE clipboard_item SET timestamp = ? WHERE id = ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, timestamp)
        sqlite3_bind_int64(statement, 2, id)

        if sqlite3_step(statement) != SQLITE_DONE {
            print("❌ 更新时间戳失败")
        }

        loadItems()
    }

    // MARK: - 过期清理

    /// 固定保留天数：超过该天数的未置顶记录自动清理
    static let retentionDays: Double = 3

    /// 清理超过保留天数的记录（置顶豁免）
    func cleanExpired() {
        let cutoffTimestamp = Date()
            .addingTimeInterval(-Self.retentionDays * 24 * 60 * 60)
            .timeIntervalSince1970

        // 先找出过期的图片条目，删除图片文件
        let expiredImages = items.filter {
            $0.type == .image &&
            !$0.isPinned &&
            $0.timestamp.timeIntervalSince1970 < cutoffTimestamp
        }
        for item in expiredImages {
            if let path = item.imagePath {
                ImageStorage.shared.deleteImage(at: path)
            }
        }

        // 删除过期且未置顶的记录
        let sql = """
            DELETE FROM clipboard_item
            WHERE timestamp < ? AND is_pinned = 0
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_double(statement, 1, cutoffTimestamp)

        if sqlite3_step(statement) == SQLITE_DONE {
            let count = sqlite3_changes(db)
            if count > 0 {
                print("🧹 已清理 \(count) 条过期记录")
            }
        }

        loadItems()
    }
}
