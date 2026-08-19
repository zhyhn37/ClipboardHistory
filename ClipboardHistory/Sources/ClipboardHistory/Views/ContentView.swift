import SwiftUI

/// 主界面 — 搜索框 + 置顶区 + 历史列表
struct ContentView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var searchText = ""
    @State private var isPinnedExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            SearchBar(text: $searchText)

            Divider()

            // 内容区域
            if displayItems.isEmpty {
                EmptyStateView()
            } else {
                scrollableList
            }
        }
        .frame(width: 360)
        .frame(height: windowHeight)
        .background(Color.white)
        .onChange(of: pinnedItems.count) { count in
            if count > 3 {
                isPinnedExpanded = false
            }
        }
    }

    // MARK: - 窗口高度计算

    /// 根据条目数量和折叠状态动态计算窗口高度，最多显示 5 条
    private var windowHeight: CGFloat {
        let searchBarHeight: CGFloat = 36

        if displayItems.isEmpty {
            return 200  // 空状态
        }

        // 置顶区高度
        let pinnedHeight: CGFloat
        if pinnedItems.isEmpty {
            pinnedHeight = 0
        } else if isPinnedExpanded {
            // 展开：标题 + 卡片
            let visiblePinned = min(pinnedItems.count, 5)
            pinnedHeight = 28 + CGFloat(visiblePinned) * cardHeight
        } else {
            // 折叠：仅标题
            pinnedHeight = 28
        }

        // 历史区卡片数（最多 5 条总量限制）
        let maxVisible = 5
        let visiblePinnedCards = (pinnedItems.isEmpty || !isPinnedExpanded) ? 0 : min(pinnedItems.count, maxVisible)
        let remaining = maxVisible - visiblePinnedCards
        let visibleHistoryCards = min(unpinnedItems.count, remaining)
        let historyHeight = CGFloat(visibleHistoryCards) * cardHeight

        let bottomPadding: CGFloat = 8

        return searchBarHeight + pinnedHeight + historyHeight + bottomPadding
    }

    /// 单条卡片估算高度
    private let cardHeight: CGFloat = 56

    /// 总条目数（置顶 + 历史）
    private var totalCardCount: Int {
        displayItems.count
    }

    // MARK: - 滚动列表

    private var scrollableList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 置顶区
                if !pinnedItems.isEmpty {
                    pinnedSectionHeader
                    if isPinnedExpanded {
                        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardCard(item: item)
                            if index < pinnedItems.count - 1 {
                                cardDivider
                            }
                        }
                    }
                    sectionDivider
                }

                // 历史区
                ForEach(Array(unpinnedItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardCard(item: item)
                    if index < unpinnedItems.count - 1 {
                        cardDivider
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - 数据过滤

    private var displayItems: [ClipboardItem] {
        if searchText.isEmpty {
            return dataStore.items
        }
        return dataStore.items.filter { item in
            item.textPreview?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    private var pinnedItems: [ClipboardItem] {
        displayItems.filter(\.isPinned)
    }

    private var unpinnedItems: [ClipboardItem] {
        displayItems.filter { !$0.isPinned }
    }

    // MARK: - 视图组件

    private var pinnedSectionHeader: some View {
        Button(action: {
            if shouldAutoCollapse {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPinnedExpanded.toggle()
                }
            }
        }) {
            HStack {
                Label("置顶", systemImage: "pin.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if shouldAutoCollapse {
                    HStack(spacing: 4) {
                        Text("\(pinnedItems.count) 条")
                            .font(.system(size: 10))
                        Image(systemName: isPinnedExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.blue.opacity(0.7))
                } else {
                    Text("\(pinnedItems.count) 项")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.04))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!shouldAutoCollapse)
    }

    /// 置顶超过 3 条时才允许折叠
    private var shouldAutoCollapse: Bool {
        pinnedItems.count > 3
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }

    private var cardDivider: some View {
        Divider().padding(.horizontal, 12)
    }
}
