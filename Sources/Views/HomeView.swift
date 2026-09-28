import SwiftUI
import SwiftData

/// 主页：全部库存总览（未设置区域时显示）
/// 骨架对齐 BatteryInsight：系统 List + Section（分组背景 + 分组卡片 + 小节标题）
/// 保留功能交互：大标题滚动收缩胶囊、搜索/添加、统计概览卡、状态分组、
/// 物品卡（左信息右状态 + 剩余进度条）、底部筛选、zoom 详情转场
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @State private var categoryFilter: Category? = nil
    @State private var roomFilter: String? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showAddSheet = false
    @State private var selectedItem: InventoryItem? = nil
    /// 顶栏收缩进度：0=大标题展开，1=完全收成胶囊（随滚动偏移连续变化）
    @State private var titleProgress: CGFloat = 0
    /// 页面转场命名空间：详情页 zoom 打开/关闭动画与物品卡匹配
    @Namespace private var namespace

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
            List {
                // 搜索（展开时显示）
                if showSearch {
                    searchField
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                }
                // 已选筛选标签
                if let cat = categoryFilter {
                    FilterChip(label: "品类：\(cat.rawValue)") { categoryFilter = nil }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
                }
                if let room = roomFilter {
                    FilterChip(label: "位置：\(room)") { roomFilter = nil }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
                }

                // 统计概览卡
                statsBanner
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))

                // 需要关注（橙色描边高亮）
                if !attentionItems.isEmpty {
                    Section {
                        itemRows(attentionItems, emphasized: true)
                    } header: {
                        sectionHeader("需要关注", count: attentionItems.count, color: .orange)
                    }
                }

                // 库存充足
                Section {
                    if sufficientItems.isEmpty {
                        emptyCard(text: "还没有物品，点右上角 + 添加第一个物品", showAdd: true)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        itemRows(sufficientItems)
                    }
                } header: {
                    sectionHeader("库存充足", count: sufficientItems.count, color: Color(red: 0.36, green: 0.62, blue: 0.48))
                }

                // 尚未拆封
                Section {
                    if unopenedItems.isEmpty {
                        emptyCard(text: "还没有拆封记录", showAdd: false)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        itemRows(unopenedItems)
                    }
                } header: {
                    sectionHeader("尚未拆封", count: unopenedItems.count, color: .gray)
                }

                // 底部提示
                footerHint
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 12, trailing: 20))
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .scrollIndicators(.hidden)
            // 滚动偏移连续读取：统计区一上移即开始收缩（进度 = offset / 10，10pt 完全收起）
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, offset in
                let p = min(max(offset / 10, 0), 1)
                if abs(p - titleProgress) > 0.001 {
                    titleProgress = p
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                // 固定高度 64pt 顶栏容器：大标题 ↔ 玻璃胶囊随滚动比例连续变换
                ZStack {
                    // 胶囊标题（随进度淡入放大）
                    Text("家庭库存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.adaptiveTextGreen)
                        .padding(.horizontal, 20)
                        .frame(height: 40)
                        .glassEffect(.clear, in: .capsule)
                        .opacity(Double(titleProgress))
                        .scaleEffect(0.85 + 0.15 * titleProgress)

                    // 大标题 + 副标题（随进度淡出缩小）
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("家庭库存")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color.adaptiveTextGreen)
                            Text("今天需要关注\(attentionItems.count)件 · 共\(filteredItems.count)个品种")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .opacity(Double(1 - titleProgress))
                    .scaleEffect(1 - 0.08 * titleProgress, anchor: .topLeading)

                    // 右上角按钮组：独立 + 胶囊 + 搜索
                    HStack {
                        Spacer()
                        HStack(spacing: 10) {
                            SolidAddCapsule { showAddSheet = true }
                            GlassCircleButton(icon: showSearch ? "xmark" : "magnifyingglass") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showSearch.toggle()
                                    if !showSearch { searchText = "" }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
                .frame(height: 64, alignment: .top)
            }
            // 类别/位置筛选：固定在底部，与 tab 栏同一层级
            .safeAreaInset(edge: .bottom, spacing: 0) {
                filterRow
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            // 添加物品：二级页面（push）
            .navigationDestination(isPresented: $showAddSheet) {
                ItemEditView(mode: .add)
            }
            // 物品详情：zoom 转场
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
                    .navigationTransition(.zoom(sourceID: item.id, in: namespace))
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

    // MARK: - 概览

    private var statsBanner: some View {
        HomeCard {
            HStack(spacing: 0) {
                statColumn(icon: "exclamationmark.circle.fill", color: .orange,
                           value: attentionItems.count, label: "需要关注")
                statDivider
                statColumn(icon: "square.grid.2x2.fill", color: Color(red: 0.36, green: 0.62, blue: 0.48),
                           value: filteredItems.count, label: "消耗品种类")
                statDivider
                statColumn(icon: "shippingbox.fill", color: .gray,
                           value: unopenedItems.count, label: "尚未拆封")
            }
        }
    }

    private func statColumn(icon: String, color: Color, value: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.adaptiveSeparator)
            .frame(width: 1, height: 34)
    }

    // MARK: - 分区（BatteryInsight 风格：小节标题 + 右侧计数）

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Text("\(count) 件")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }

    private func itemRows(_ list: [InventoryItem], emphasized: Bool = false) -> some View {
        ForEach(list) { item in
            ItemRow(item: item, emphasized: emphasized)
                // zoom 转场源：点按进入详情时从这张卡片放大，返回时缩回
                .matchedTransitionSource(id: item.id, in: namespace) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedItem = item }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        }
    }

    private func emptyCard(text: String, showAdd: Bool) -> some View {
        HomeCard {
            VStack(spacing: 10) {
                Image(systemName: "tray")
                    .font(.system(size: 26))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                if showAdd {
                    Button {
                        showAddSheet = true
                    } label: {
                        Text("去添加")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - 底部筛选与提示

    private var filterRow: some View {
        HStack(spacing: 8) {
            chip("类别") {
                menu(of: Category.allCases.map(\.rawValue),
                     selected: categoryFilter?.rawValue,
                     select: { categoryFilter = Category(rawValue: $0) })
            }
            chip("位置") {
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
            Label(title, systemImage: "line.3.horizontal.decrease")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.28, green: 0.52, blue: 0.40))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(red: 0.28, green: 0.52, blue: 0.40).opacity(0.10)))
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

/// 首页/区域页统一卡片（BatteryInsight 记录卡写法）：
/// ultraThinMaterial 微透明白底 + 系统分隔线细描边；深浅模式自适应、通透不显黑。
/// 需关注卡片：橙色描边高亮。
struct HomeCard<Content: View>: View {
    var emphasized: Bool = false
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        emphasized ? Color.orange.opacity(0.45) : Color.adaptiveSeparator.opacity(0.5),
                        lineWidth: 1
                    )
            }
    }
}

/// 物品卡（参考「有余」：左信息 + 右状态/天数 + 底部进度条，信息层级更清晰）
/// 进度条表示「剩余库存占比」：满库时 100%，随消耗逐渐缩短，用完归零。
/// 状态胶囊：纯色底 + 白字（非液态玻璃），颜色按需关注/充足/未拆封区分
/// 库存/使用中：黑色（primary）加大一号显示
struct ItemRow: View {
    let item: InventoryItem
    var emphasized: Bool = false

    /// 剩余占比 = 库存 / (库存 + 使用中)，满库 100%，用一点少一点
    private var progress: Double {
        let total = item.totalStock + item.inUse
        guard total > 0 else { return 0 }
        return min(max(Double(item.totalStock) / Double(total), 0), 1)
    }

    var body: some View {
        HomeCard(emphasized: emphasized) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(categoryColor(item.category))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Text("\(item.category.rawValue) · \(item.location)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            Label("库存 \(item.totalStock)", systemImage: "shippingbox")
                            Label("使用中 \(item.inUse)", systemImage: "hand.raised")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        SolidStatusCapsule(text: item.status.title, color: statusColor(item.status))
                        if item.isOpened {
                            Text("约\(item.remainingDays)天")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(statusColor(item.status))
                        } else {
                            Text("未拆封")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                // 进度条（剩余量）：加粗 + 右侧剩余百分比
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.adaptiveTrack)
                            Capsule()
                                .fill(statusColor(item.status))
                                .frame(width: geo.size.width * progress)
                                .animation(.snappy(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 8)
                    Text("剩余\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }
            }
        }
    }

    private func statusColor(_ status: StockStatus) -> Color {
        switch status {
        case .attention: return .orange
        case .sufficient: return Color(red: 0.36, green: 0.62, blue: 0.48)
        case .unopened: return .gray
        }
    }

    private func categoryColor(_ category: Category) -> Color {
        switch category {
        case .momAndBaby: return Color(red: 0.93, green: 0.45, blue: 0.55)
        case .paper: return Color(red: 0.35, green: 0.55, blue: 0.85)
        case .washCare: return Color(red: 0.25, green: 0.65, blue: 0.60)
        case .food: return Color(red: 0.95, green: 0.65, blue: 0.25)
        case .household: return Color(red: 0.60, green: 0.50, blue: 0.85)
        case .other: return .gray
        }
    }
}
