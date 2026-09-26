import SwiftUI

/// 通知：tab 栏中间「+」按钮触发的添加物品请求
extension Notification.Name {
    static let openAddItem = Notification.Name("openAddItem")
}

/// 根视图：底部导航（首页 / 设置）
/// 使用 iOS 26 官方 TabView——自带液态玻璃悬浮 tab bar 与官方 tap 切换交互
/// tab 栏中间悬浮绿色胶囊「+」按钮：点击触发添加物品
struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home = "首页"
        case settings = "设置"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
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

            // 悬浮绿色胶囊「+」：仅首页显示，点击触发添加物品
            if selection == .home {
                Button {
                    NotificationCenter.default.post(name: .openAddItem, object: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 46)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.42, green: 0.70, blue: 0.54),
                                        Color(red: 0.26, green: 0.55, blue: 0.41)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        )
                        .shadow(color: Color(red: 0.26, green: 0.55, blue: 0.41).opacity(0.45),
                                radius: 10, x: 0, y: 4)
                }
                .padding(.bottom, 12)
            }
        }
    }
}

/// 全应用统一背景：浅色模式纯白 / 深色模式深灰（配合官方液态玻璃）
struct AppBackground: View {
    var body: some View {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(white: 0.07, alpha: 1) : UIColor.white
        }).ignoresSafeArea()
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
