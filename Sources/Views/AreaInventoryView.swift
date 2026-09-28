import SwiftUI
import SwiftData

/// 分区库存管理页：显示某个区域的全部物品，独立管理（拆封/补货/详情）
/// 入口在底部 tab 栏（设置页添加区域后自动出现）
/// 顶栏：搜索按钮在最左侧、添加按钮在最右侧，均为官方液态玻璃圆形按钮
/// 布局复用主页卡片样式：概览条 + 物品卡列表 + zoom 详情转场
struct AreaInventoryView: View {
    @Environment(\.modelContext) private var modelContext
    let area: String
    @Query(sort: \InventoryItem.createdAt) private var allItems: [InventoryItem]
    @AppStorage("pendingAddLocation") private var pendingAddLocation = ""

    @State private var selectedItem: InventoryItem? = nil
    @State private var showAdd = false
    @State private var showSearch = false
    @State private var searchText = ""
    @Namespace private var namespace

    /// 该区域的物品（支持搜索过滤）
    private var items: [InventoryItem] {
        var list = allItems.filter { $0.location == area }
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    private var attentionCount: Int { items.filter { $0.status == .attention }.count }
    private var unopenedCount: Int { items.filter { $0.status == .unopened }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 搜索（展开时显示，带顶部滑入过渡，主页同款）
                    if showSearch {
                        SearchField(text: $searchText)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // 该区域概览
                    overviewCard

                    if items.isEmpty {
                        EmptyCard(icon: "mappin.and.ellipse",
                                  text: searchText.isEmpty ? "「\(area)」还没有物品" : "没有找到「\(searchText)」",
                                  addButtonTitle: searchText.isEmpty ? "添加物品到此区域" : nil,
                                  addAction: {
                                      pendingAddLocation = area
                                      showAdd = true
                                  })
                    } else {
                        SectionHeader(title: "物品", count: items.count)
                        itemRows
                    }

                    FooterHint(text: "此页面仅显示存放位置为「\(area)」的物品")
                    Spacer().frame(height: 96)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                // 顶栏：搜索圆形按钮（最左）+ 区域名胶囊（中）+ 添加圆形按钮（最右）
                GlassTopBar(
                    title: area,
                    leading: {
                        // 搜索：液态玻璃圆形按钮（最左侧）
                        GlassCircleButton(icon: showSearch ? "xmark" : "magnifyingglass") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSearch.toggle()
                                if !showSearch { searchText = "" }
                            }
                        }
                    },
                    trailing: {
                        // 添加该区域物品：液态玻璃圆形按钮（最右侧），位置自动预填该区域
                        Button {
                            pendingAddLocation = area
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .glassEffect(.regular.tint(Color.brandGreen), in: .circle)
                                .contentShape(Rectangle())
                        }
                    }
                )
            }
            // 添加该区域物品：二级页面，存储位置预填为当前区域
            .navigationDestination(isPresented: $showAdd) {
                ItemEditView(mode: .add)
            }
            // 物品详情：zoom 转场（从卡片放大打开 / 反向缩回关闭）
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
                    .navigationTransition(.zoom(sourceID: item.id, in: namespace))
            }
        }
        .tint(Color.brandTint)
    }

    // MARK: - 概览

    private var overviewCard: some View {
        HomeCard {
            HStack(spacing: 0) {
                StatColumn(icon: "shippingbox.fill", color: Color.brandGreen,
                           value: items.count, label: "物品")
                StatDivider()
                StatColumn(icon: "exclamationmark.circle.fill", color: .orange,
                           value: attentionCount, label: "需关注")
                StatDivider()
                StatColumn(icon: "shippingbox", color: .gray,
                           value: unopenedCount, label: "未拆封")
            }
        }
    }

    // MARK: - 列表

    private var itemRows: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                ItemRow(item: item)
                    // zoom 转场源：点按进入详情时从这张卡片放大，返回时缩回
                    .matchedTransitionSource(id: item.id, in: namespace) { source in
                        source.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedItem = item }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}
