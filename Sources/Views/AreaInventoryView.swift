import SwiftUI
import SwiftData

/// 分区库存管理页：显示某个区域的全部物品，独立管理（拆封/补货/详情）
/// 入口在底部 tab 栏（设置页添加区域后自动出现）；顶栏右上角 + 胶囊可直接添加该区域物品
/// 布局复用主页卡片样式：概览条 + 物品卡列表 + zoom 详情转场
struct AreaInventoryView: View {
    @Environment(\.modelContext) private var modelContext
    let area: String
    @Query(sort: \InventoryItem.createdAt) private var allItems: [InventoryItem]
    @AppStorage("pendingAddLocation") private var pendingAddLocation = ""

    @State private var selectedItem: InventoryItem? = nil
    @State private var showAdd = false
    @Namespace private var namespace

    /// 该区域的物品
    private var items: [InventoryItem] {
        allItems.filter { $0.location == area }
    }

    private var attentionCount: Int { items.filter { $0.status == .attention }.count }
    private var unopenedCount: Int { items.filter { $0.status == .unopened }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 该区域概览
                    overviewCard

                    if items.isEmpty {
                        emptyCard
                    } else {
                        sectionHeader("物品", count: items.count)
                        itemRows
                    }

                    footerHint
                    Spacer().frame(height: 96)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                // 顶栏：区域名 + 右上角独立 + 胶囊（添加该区域物品，位置自动预填）
                GlassTopBar(
                    title: area,
                    trailing: {
                        SolidAddCapsule {
                            pendingAddLocation = area
                            showAdd = true
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
        .tint(Color(red: 0.30, green: 0.55, blue: 0.42))
    }

    // MARK: - 概览

    private var overviewCard: some View {
        HomeCard {
            HStack(spacing: 0) {
                statColumn(icon: "shippingbox.fill", color: Color(red: 0.36, green: 0.62, blue: 0.48),
                           value: items.count, label: "物品")
                statDivider
                statColumn(icon: "exclamationmark.circle.fill", color: .orange,
                           value: attentionCount, label: "需关注")
                statDivider
                statColumn(icon: "shippingbox", color: .gray,
                           value: unopenedCount, label: "未拆封")
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

    // MARK: - 列表

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveTextGreen)
            Spacer()
            Text("\(count) 件")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
        }
        .padding(.top, 6)
    }

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

    private var emptyCard: some View {
        HomeCard {
            VStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 26))
                    .foregroundColor(.secondary)
                Text("「\(area)」还没有物品")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Button {
                    pendingAddLocation = area
                    showAdd = true
                } label: {
                    Text("添加物品到此区域")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var footerHint: some View {
        Text("此页面仅显示存放位置为「\(area)」的物品")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
