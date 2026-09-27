import SwiftUI
import SwiftData

/// 根视图：底部导航（首页 / 各区域 / 设置）
/// 使用 iOS 26 官方 TabView——自带液态玻璃悬浮 tab bar 与官方 tap 切换交互
/// 区域入口：设置页添加区域后，底部自动出现对应分区 tab（按区域管理库存）
/// 添加入口：不在 tab 栏内，主页/区域页顶栏右上角有独立纯色 + 胶囊按钮（参考「有余」布局）
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryArea.createdAt) private var areas: [InventoryArea]
    @State private var selection: String = "home"

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag("home")

            // 区域分区 tab：每个区域一个独立库存管理入口（随设置页添加/删除自动增减）
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
        .tint(Color(red: 0.30, green: 0.55, blue: 0.42))
        // 跟随系统深浅色外观（不锁浅色），背景/卡片/文字均自适应
        // 区域被删除时，若正停留在该区域 tab，自动切回首页
        .onChange(of: areas.map(\.id)) { _, ids in
            if !ids.contains(where: { "area-\($0.uuidString)" == selection }) {
                selection = "home"
            }
        }
    }
}

/// 全应用统一背景：浅色=纯白，深色=近黑（自适应）
struct AppBackground: View {
    var body: some View {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(white: 0.08, alpha: 1) : UIColor.white
        })
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
