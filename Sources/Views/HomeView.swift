import SwiftUI
import SwiftData

/// 首页：库存总览、分类筛选、物品列表（参考「有余」布局：统计卡、分区、进度条、底部筛选）
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @State private var categoryFilter: Category? = nil
    @State private var roomFilter: String? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showAddSheet = false
    @State private var selectedItem: InventoryItem? = nil

    private var availableRooms: [String] {
        Array(Set(items.map(\.location))).sorted()
    }

    /// 过滤后的物品
    private var filteredItems: [InventoryItem] {
        var list = items
        if let cat = categoryFilter {
            list = list.filter { $0.category == cat }
        }
        if let room = roomFilter {
            list = list.filter { $0.location == room }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private var attentionItems: [InventoryItem] {
        filteredItems.filter { $0.status == .attention }
    }
    private var sufficientItems: [InventoryItem] {
        filteredItems.filter { $0.status == .sufficient }
    }
    private var unopenedItems: [InventoryItem] {
        filteredItems.filter { $0.status == .unopened }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 搜索（展开时显示）
                    if showSearch {
                        searchField
                    }
                    // 已选筛选标签
                    if let cat = categoryFilter {
                        FilterChip(label: "品类：\(cat.rawValue)") { categoryFilter = nil }
                    }
                    if let room = roomFilter {
                        FilterChip(label: "房间：\(room)") { roomFilter = nil }
                    }

                    // 统计卡片（两块独立分开）
                    statsRow

                    // 各分区（分开呈现，区块标题右侧放辅助信息）
                    if !attentionItems.isEmpty {
                        sectionHeader("需关注", trailing: "\(attentionItems.count) 件")
                        itemRows(attentionItems)
                    }

                    sectionHeader("库存充足", trailing: "最近更新")
                    itemRows(sufficientItems)

                    sectionHeader("尚未拆封", trailing: unopenedItems.isEmpty ? "还没有拆封记录" : "\(unopenedItems.count) 件")
                    if unopenedItems.isEmpty {
                        GlassCard {
                            Text("还没有拆封记录")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(20)
                        }
                    } else {
                        itemRows(unopenedItems)
                    }

                    // 底部：筛选 + 提示
                    filterRow
                    footerHint

                    Spacer().frame(height: 96)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                GlassTopBar(
                    title: "家庭库存",
                    leading: { GlassCircleButton(icon: "plus") { showAddSheet = true } },
                    trailing: { GlassCircleButton(icon: showSearch ? "xmark" : "magnifyingglass") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    } }
                )
            }
            // 添加物品：二级页面（push）
            .navigationDestination(isPresented: $showAddSheet) {
                ItemEditView(mode: .add)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
        .tint(Color(red: 0.30, green: 0.55, blue: 0.42))
    }

    // MARK: - 搜索

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索物品", text: $searchText)
                .font(.system(size: 15))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.adaptiveCardFill)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color.adaptiveCardStroke, lineWidth: 1))
        )
    }

    // MARK: - 统计

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(value: "\(attentionItems.count)", label: "需要关注")
            statCard(value: "\(filteredItems.count)", label: "消耗品种类")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    // MARK: - 区块

    private func sectionHeader(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.adaptiveTextGreen)
            Spacer()
            Text(trailing)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.top, 6)
    }

    private func itemRows(_ list: [InventoryItem]) -> some View {
        VStack(spacing: 12) {
            ForEach(list) { item in
                ItemRow(item: item)
                    .onTapGesture { selectedItem = item }
            }
        }
    }

    // MARK: - 底部筛选与提示

    private var filterRow: some View {
        HStack(spacing: 8) {
            chip("类别") {
                menu(of: Category.allCases.map(\.rawValue),
                     selected: categoryFilter?.rawValue,
                     select: { categoryFilter = Category(rawValue: $0) })
            }
            chip("房间") {
                menu(of: availableRooms,
                     selected: roomFilter,
                     select: { roomFilter = $0 })
            }
            Spacer()
        }
    }

    private var footerHint: some View {
        Text("拆封后开始计算预计可用天数")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - 筛选辅助

    private func chip(_ title: String, @ViewBuilder menu: @escaping () -> some View) -> some View {
        Menu {
            menu()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .glassEffect(.clear, in: .capsule)
        }
    }

    private func menu(of options: [String], selected: String?, select: @escaping (String) -> Void) -> some View {
        ForEach(options, id: \.self) { opt in
            Button {
                select(opt)
            } label: {
                if selected == opt {
                    Label(opt, systemImage: "checkmark")
                } else {
                    Text(opt)
                }
            }
        }
    }
}

/// 筛选标签
struct FilterChip: View {
    let label: String
    let clear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Button(action: clear) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
    }
}

/// 首页物品行（参考「有余」：左信息 + 右状态/天数 + 底部进度条）
struct ItemRow: View {
    let item: InventoryItem

    private var progress: Double {
        guard item.totalStock > 0 else { return 0 }
        return min(max(Double(item.inUse) / Double(item.totalStock), 0), 1)
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(item.category.rawValue)·\(item.location)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("库存 \(item.totalStock)·使用中 \(item.inUse)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        StatusCapsule(text: item.status.title,
                                      color: statusColor(item.status))
                        Text("约\(item.remainingDays)天")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                    }
                }
                // 进度条（单独一行，与信息分开）
                HStack(spacing: 8) {
                    Text("已用")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.06))
                            Capsule()
                                .fill(statusColor(item.status))
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 6)
                    Text("\(item.inUse)/\(item.totalStock)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
        }
    }

    private func statusColor(_ status: StockStatus) -> Color {
        switch status {
        case .attention: return Color.orange
        case .sufficient: return Color(red: 0.36, green: 0.62, blue: 0.48)
        case .unopened: return Color.gray
        }
    }
}
