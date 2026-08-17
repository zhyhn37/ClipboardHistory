import SwiftUI

/// 设置窗口 — 开机启动
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 存储时长说明（固定保留 3 天，不可配置）
            Text("记录自动保留 3 天，置顶记录永久保留")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // 开机启动
            Toggle("开机自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    MenuBarController.updateAutoLaunch(enabled: newValue)
                }

            // 快捷键提示
            VStack(alignment: .leading, spacing: 4) {
                Text("快捷键：⌘⇧V")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("首次使用快捷键需要在「系统设置 → 隐私与安全性 → 辅助功能」中授予权限")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 340, height: 200)
    }
}
