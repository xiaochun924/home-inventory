import SwiftUI

/// 通知：tab 栏中间「+」按钮触发的添加物品请求
extension Notification.Name {
    static let openAddItem = Notification.Name("openAddItem")
}

/// 根视图：底部导航（首页 / 设置）
/// 使用 iOS 26 官方 TabView——自带液态玻璃悬浮 tab bar 与官方 tap 切换交互
/// tab 栏中间为「+」tab（系统原生，稳定位于 tab 栏正中、与图标同一排）：点击触发添加物品
struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home = "首页"
        case add = "添加"
        case settings = "设置"
        var id: String { rawValue }
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(Tab.home)

            // 中间「+」tab：系统原生渲染，位置绝对位于 tab 栏正中
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("", systemImage: "plus.circle.fill") }
                .tag(Tab.add)

            SettingsView()
                .background(AppBackground().ignoresSafeArea())
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        // iOS 26 官方液态玻璃 tab bar：滚动时自动最小化，tap 切换为系统原生交互
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Color(red: 0.30, green: 0.55, blue: 0.42))
        // 跟随系统深浅色外观（不锁浅色），背景/卡片/文字均自适应
        .onChange(of: selection) { _, newValue in
            if newValue == .add {
                NotificationCenter.default.post(name: .openAddItem, object: nil)
                selection = .home
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
        let schema = Schema([InventoryItem.self, UnpackRecord.self, RestockRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return RootView()
            .modelContainer(container)
    }
}
#endif
