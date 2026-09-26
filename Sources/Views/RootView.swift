import SwiftUI

/// 根视图：底部导航（首页 / 设置）
/// 使用 iOS 26 官方 TabView——自带液态玻璃悬浮 tab bar 与官方 tap 切换交互
struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home = "首页"
        case settings = "设置"
        var id: String { rawValue }
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(Tab.home)

            SettingsView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        // iOS 26 官方液态玻璃 tab bar：滚动时自动最小化，tap 切换为系统原生交互
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Color(red: 0.30, green: 0.55, blue: 0.42))
    }
}

/// 全应用统一背景：纯白（配合官方液态玻璃）
struct AppBackground: View {
    var body: some View {
        Color.white.ignoresSafeArea()
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let schema = Schema([InventoryItem.self, UnpackRecord.self, RestockRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return RootView()
            .modelContainer(container)
    }
}
#endif
