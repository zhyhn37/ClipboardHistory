import SwiftUI

/// 主界面 — 搜索框 + 置顶区 + 历史列表
struct ContentView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var searchText = ""

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
    }

    // MARK: - 窗口高度计算

    /// 根据条目数量动态计算窗口高度，最多显示 5 条
    private var windowHeight: CGFloat {
        // 搜索框高度
        let searchBarHeight: CGFloat = 36

        if displayItems.isEmpty {
            return 200  // 空状态
        }

        // 置顶区标题（有置顶条目时出现）
        let pinnedHeaderHeight: CGFloat = pinnedItems.isEmpty ? 0 : 28

        // 一屏最多显示 5 条
        let visibleCards = min(totalCardCount, 5)
        let cardsHeight = CGFloat(visibleCards) * cardHeight

        // 底部留白
        let bottomPadding: CGFloat = 8

        return searchBarHeight + pinnedHeaderHeight + cardsHeight + bottomPadding
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
                    ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardCard(item: item)
                        if index < pinnedItems.count - 1 {
                            cardDivider
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
        HStack {
            Label("置顶", systemImage: "pin.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(pinnedItems.count) 项")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.04))
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
