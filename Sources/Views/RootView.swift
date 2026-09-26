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
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 液态玻璃底部导航
            GlassTabBar(selection: $selection)
        }
    }
}

/// 全应用统一背景：柔和浅绿 + 光斑
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.96, blue: 0.93),
                         Color(red: 0.86, green: 0.92, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // 柔光光斑，增强液态玻璃通透感
            Circle()
                .fill(Color(red: 0.7, green: 0.85, blue: 0.75).opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -140, y: -300)
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: 150, y: 280)
        }
        .ignoresSafeArea()
    }
}

/// 液态玻璃底部导航条
struct GlassTabBar: View {
    @Binding var selection: RootView.Tab
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 16) {
            tabButton(.home, icon: "house.fill")
            Spacer()
            // 中部悬浮加号（新增物品入口占位，由首页处理）
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color(red: 0.36, green: 0.62, blue: 0.48)))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
            Spacer()
            tabButton(.settings, icon: "gearshape.fill")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.white.opacity(0.55))
                .background(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 6)
        )
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
