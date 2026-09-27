import SwiftUI

// ===== 深色模式自适应 =====
extension Color {
    /// 自适应卡片/字段底色（浅色模式=半透明白，深色模式=半透明深灰）
    static let adaptiveCardFill = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 0.60) : UIColor(white: 1.0, alpha: 0.50)
    })
    /// 自适应卡片描边
    static let adaptiveCardStroke = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.20) : UIColor(white: 1.0, alpha: 0.60)
    })
    /// 自适应标题绿（浅色=深墨绿，深色=亮绿，保证两种模式下可读）
    static let adaptiveTextGreen = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.80, blue: 0.68, alpha: 1)
            : UIColor(red: 0.22, green: 0.40, blue: 0.30, alpha: 1)
    })
    /// 自适应分隔线/细描边（浅色=黑6%，深色=白12%）
    static let adaptiveSeparator = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.12) : UIColor(white: 0.0, alpha: 0.06)
    })
    /// 自适应进度条轨道（浅色=黑7%，深色=白15%）
    static let adaptiveTrack = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.15) : UIColor(white: 0.0, alpha: 0.07)
    })
    /// 自适应卡片底（浅色=近白浅绿/浅橙，深色=深灰卡片）
    static func adaptiveCardBackground(emphasized: Bool) -> Color {
        Color(uiColor: UIColor { t in
            if t.userInterfaceStyle == .dark {
                return emphasized
                    ? UIColor(red: 0.32, green: 0.23, blue: 0.17, alpha: 1)   // 深色需关注：暗橙
                    : UIColor(white: 0.16, alpha: 1)                          // 深色普通：深灰
            } else {
                return emphasized
                    ? UIColor(red: 1.00, green: 0.96, blue: 0.93, alpha: 1)   // 浅色需关注：浅橙
                    : UIColor(red: 0.97, green: 0.985, blue: 0.97, alpha: 1) // 浅色普通：近白浅绿
            }
        })
    }
}

// ================= 液态玻璃悬浮顶栏（全局统一规范） =================
// 规范：纯透明导航栏；左上角圆形玻璃返回按钮；中间悬浮玻璃胶囊标题；
// 完全隐藏系统导航栏；不加白色蒙皮 / 磨砂遮挡。
// 全部使用 iOS 26 官方 Liquid Glass（glassEffect / GlassEffectContainer）。
struct GlassTopBar<Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    init(title: String,
         @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        // 玻璃容器：让左右圆形按钮与中间胶囊标题共享玻璃采样区，效果更一致
        GlassEffectContainer {
            // 标题用 ZStack 绝对居中，不受左右按钮宽度影响；左右按钮覆盖在两侧
            ZStack {
                // 中间悬浮玻璃胶囊标题（官方 Liquid Glass）
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.adaptiveTextGreen)
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .glassEffect(.clear, in: .capsule)

                HStack {
                    leading()
                    Spacer()
                    trailing()
                }
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
    }
}

/// 圆形玻璃返回按钮（官方 Liquid Glass，可交互）
struct GlassCircleButton: View {
    let icon: String
    var tint: Color = Color(red: 0.30, green: 0.55, blue: 0.42)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 40, height: 40)
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

/// 液态玻璃卡片（官方 Liquid Glass 容器）
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
    }
}

/// 胶囊主按钮（官方 Liquid Glass，tint 上色 + 可交互）
struct GlassCapsuleButton: View {
    let title: String
    var tint: Color = Color(red: 0.36, green: 0.62, blue: 0.48)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .glassEffect(.regular.tint(tint).interactive(), in: .capsule)
        }
    }
}

/// 状态胶囊标签（液态玻璃版，详情页等场景使用）
struct StatusCapsule: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .glassEffect(.clear, in: .capsule)
    }
}

/// 纯色状态胶囊标签（主页使用，非液态玻璃）：纯色胶囊底 + 白字，颜色按状态区分
struct SolidStatusCapsule: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color))
    }
}
