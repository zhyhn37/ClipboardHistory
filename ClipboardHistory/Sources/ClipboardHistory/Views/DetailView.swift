import SwiftUI

/// 条目检视窗口 — 显示完整内容 + 操作按钮
struct DetailView: View {
    let item: ClipboardItem
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            ScrollView {
                contentArea
                    .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 底部操作栏
            HStack(spacing: 12) {
                Button(action: copyAction) {
                    Label("复制", systemImage: "doc.on.doc")
                        .frame(minWidth: 72)
                }

                Button(action: pasteAction) {
                    Label("粘贴", systemImage: "arrow.forward.doc")
                        .frame(minWidth: 72)
                }

                Spacer()

                Text(formatTimestamp(item.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: deleteAction) {
                    Label("删除", systemImage: "trash")
                        .frame(minWidth: 72)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 380, idealWidth: 420, maxWidth: 560)
        .frame(minHeight: 160, idealHeight: 300, maxHeight: 500)
        .background(Color.white)
    }

    // MARK: - 内容

    @ViewBuilder
    private var contentArea: some View {
        switch item.type {
        case .text:
            if let text = item.textContent, !text.isEmpty {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("无内容")
                    .foregroundColor(.secondary)
            }

        case .image:
            if let path = item.imagePath,
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 500, maxHeight: 400)
            } else {
                Text("图片加载失败")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 操作

    private func copyAction() {
        PasteController.shared.copyOnly(item)
    }

    private func pasteAction() {
        PasteController.shared.paste(item)
        onDismiss()
    }

    private func deleteAction() {
        DataStore.shared.deleteItem(id: item.id)
        onDismiss()
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
