import SwiftUI

/// 空状态占位视图 — 没有任何剪贴板记录时显示
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("暂无历史记录")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text("复制文字或图片后\n内容会自动出现在这里")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
