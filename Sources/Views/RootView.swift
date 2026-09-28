import SwiftUI
import SwiftData

/// 根视图：底部导航（首页 / 各区域 / 设置）
/// 使用 iOS 26 官方 TabView——自带液态玻璃悬浮 tab bar 与官方 tap 切换交互
/// 区域规则：
///  - 未设置区域时：显示「首页」（全部库存总览）
///  - 设置区域后：隐藏首页，直接进入分区管理；默认选中第一个区域（sortOrder 最小者）
///  - 区域顺序可在设置页调整（上移/下移），tab 顺序随之变化
/// 添加入口：主页/区域页顶栏右上角独立纯色 + 胶囊按钮
struct RootView: View {
    @Query(sort: \InventoryArea.sortOrder) private var areas: [InventoryArea]
    @State private var selection: String = "home"

    var body: some View {
        TabView(selection: $selection) {
            // 未设置区域时保留首页（全部总览）；设置区域后首页隐藏，直接进入分区
            if areas.isEmpty {
                HomeView()
                    .background(AppBackground().ignoresSafeArea())
                    .tabItem { Label("首页", systemImage: "house.fill") }
                    .tag("home")
            }

            // 区域分区 tab：按 sortOrder 排序，每个区域一个独立库存管理入口
            ForEach(areas) { area in
                AreaInventoryView(area: area.name)
                    .background(AppBackground().ignoresSafeArea())
                    .tabItem { Label(area.name, systemImage: "location.fill") }
                    .tag("area-\(area.id.uuidString)")
            }

            SettingsView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag("settings")
        }
        // iOS 26 官方液态玻璃 tab bar：滚动时自动最小化，tap 切换为系统原生交互
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Color(red: 0.30, green: 0.55, blue: 0.48))
        // 跟随系统深浅色外观（不锁浅色），背景/卡片/文字均自适应
        .onAppear { syncSelection() }
        // 区域增删或排序变化时同步选中项
        .onChange(of: areas.map(\.id)) { _, _ in
            syncSelection()
        }
    }

    /// 保证 selection 始终落在存在的 tab 上：
    ///  - 无区域 → 首页
    ///  - 有区域 → 默认选中第一个区域（sortOrder 最小），除非用户正停留在其他区域
    private func syncSelection() {
        if areas.isEmpty {
            selection = "home"
        } else {
            let first = "area-\(areas[0].id.uuidString)"
            if selection == "home" || !areas.contains(where: { "area-\($0.id.uuidString)" == selection }) {
                selection = first
            }
        }
    }
}

/// 全应用统一背景：系统标准背景色 systemBackground
/// 浅色=纯白（与系统默认页面/区域页底色完全一致），深色=纯黑，跟随系统深浅色外观。
/// 用系统语义色而非自定义动态闭包：线程安全（iOS 26 异步渲染线程解析动态色会崩溃）。
struct AppBackground: View {
    var body: some View {
        Color(uiColor: .systemBackground)
            .ignoresSafeArea()
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let schema = Schema([InventoryItem.self, UnpackRecord.self, RestockRecord.self, InventoryArea.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return RootView()
            .modelContainer(container)
    }
}
#endif
