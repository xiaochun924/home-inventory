import SwiftUI

/// 根视图：底部导航（首页 / 设置）
struct RootView: View {
    @State private var selection: Tab = .home

    enum Tab: String, CaseIterable, Identifiable {
        case home = "首页"
        case settings = "设置"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()
                .ignoresSafeArea()

            Group {
                switch selection {
                case .home:
                    HomeView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .settings:
                    SettingsView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: selection)

            // 液态玻璃底部导航
            GlassTabBar(selection: $selection)
        }
    }
}

/// 全应用统一背景：纯白（配合官方液态玻璃）
struct AppBackground: View {
    var body: some View {
        Color.white.ignoresSafeArea()
    }
}

/// 液态玻璃底部导航条（官方 Liquid Glass：整条玻璃胶囊，中部悬浮加号）
struct GlassTabBar: View {
    @Binding var selection: RootView.Tab

    var body: some View {
        HStack(spacing: 16) {
            tabButton(.home, icon: "house.fill")
            Spacer()
            // 中部悬浮加号（新增物品入口占位，由首页处理）
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .glassEffect(.regular.tint(Color(red: 0.36, green: 0.62, blue: 0.48)).interactive(), in: .circle)
            Spacer()
            tabButton(.settings, icon: "gearshape.fill")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Capsule().fill(.clear))
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: RootView.Tab, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selection == tab ? Color(red: 0.30, green: 0.55, blue: 0.42) : .secondary)
        }
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
