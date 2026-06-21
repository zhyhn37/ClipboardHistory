import SwiftUI

/// 设置窗口 — 存储时长 + 开机启动
struct SettingsView: View {
    @AppStorage("retentionDays") private var retentionDays = 7
    @AppStorage("launchAtLogin") private var launchAtLogin = true

    private let retentionOptions: [(String, Int)] = [
        ("1 天", 1),
        ("3 天", 3),
        ("5 天", 5),
        ("7 天", 7),
        ("永久", -1),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 存储时长
            VStack(alignment: .leading, spacing: 8) {
                Text("存储时长")
                    .font(.headline)

                Picker("", selection: $retentionDays) {
                    ForEach(retentionOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(retentionHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
        .frame(width: 340, height: 260)
    }

    private var retentionHint: String {
        if retentionDays == -1 {
            return "记录永久保留，不会被自动清理"
        } else {
            return "超过 \(retentionDays) 天的记录会自动清理"
        }
    }
}
