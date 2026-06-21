import SwiftUI

/// 单条历史卡片 — 支持文字和图片两种类型
struct ClipboardCard: View {
    let item: ClipboardItem
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // 内容区域
            contentArea

            Spacer(minLength: 8)

            // 操作按钮（hover 时显示）
            if isHovering {
                actionButtons
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundForState)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            pasteItem()
        }
    }

    // MARK: - 背景

    private var backgroundForState: some View {
        Group {
            if item.isPinned {
                Color.blue.opacity(isHovering ? 0.08 : 0.03)
            } else if isHovering {
                Color.gray.opacity(0.08)
            } else {
                Color.white
            }
        }
    }

    // MARK: - 内容区域

    @ViewBuilder
    private var contentArea: some View {
        switch item.type {
        case .text:
            textContent
        case .image:
            imageContent
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.textPreview ?? "")
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)

            Text(formatTimestamp(item.timestamp))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var imageContent: some View {
        HStack(spacing: 10) {
            // 缩略图
            thumbnailView
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("[图片]")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Text(formatTimestamp(item.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let imagePath = item.imagePath,
           let nsImage = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                )
        }
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        HStack(spacing: 6) {
            // 置顶按钮
            Button(action: togglePin) {
                Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                    .font(.system(size: 12))
                    .foregroundColor(item.isPinned ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? "取消置顶" : "置顶")

            // 删除按钮
            Button(action: deleteItem) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("删除")
        }
        .padding(.leading, 4)
    }

    // MARK: - 操作

    private func togglePin() {
        DataStore.shared.togglePin(id: item.id)
    }

    private func deleteItem() {
        DataStore.shared.deleteItem(id: item.id)
    }

    private func pasteItem() {
        // 阶段 4 实现粘贴逻辑
        PasteController.shared.paste(item)
    }

    private func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        switch interval {
        case ..<60:
            return "刚刚"
        case ..<3600:
            return "\(Int(interval / 60)) 分钟前"
        case ..<86400:
            return "\(Int(interval / 3600)) 小时前"
        case ..<604800:
            return "\(Int(interval / 86400)) 天前"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }
}
