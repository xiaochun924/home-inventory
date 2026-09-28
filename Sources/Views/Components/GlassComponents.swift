import SwiftUI

// ===== 深色模式自适应 =====
// 统一策略（BatteryInsight 风格，系统标准色）：
//  - 页面底色 = systemGroupedBackground（浅色淡灰 #F2F2F7 / 深色纯黑）
//  - 卡片底色 = ultraThinMaterial（微透明白底，叠加淡灰背景呈近白，深浅自适应）——BatteryInsight 记录卡同款
//  - 输入容器/未选中胶囊 = systemGray5（浅色 #E5E5EA / 深色 #2C2C2E），在白卡上可见、有层次
// 全部使用系统语义色：深浅模式系统自适应、跨线程安全（iOS 26 AsyncRenderer 在异步线程解析
// UIColor{...} 动态闭包会触发 Swift 6 断言崩溃，见编辑页崩溃日志）。
// 唯一保留双档动态色的是品牌绿 adaptiveTextGreen（static 无捕获闭包，线程安全）。
extension Color {
    /// 输入容器/未选中胶囊底色：系统五档灰（比卡片白稍深，层次清晰）
    static let adaptiveCardFill = Color(uiColor: .systemGray5)
    /// 自适应卡片描边：系统分隔线色
    static let adaptiveCardStroke = Color(uiColor: .separator)
    /// 自适应标题绿（浅色=深墨绿，深色=亮绿，品牌主色）
    static let adaptiveTextGreen = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.80, blue: 0.68, alpha: 1)
            : UIColor(red: 0.22, green: 0.40, blue: 0.30, alpha: 1)
    })
    /// 自适应分隔线/细描边：系统分隔线色
    static let adaptiveSeparator = Color(uiColor: .separator)
    /// 自适应进度条轨道：系统四档灰
    static let adaptiveTrack = Color(uiColor: .systemGray5)
    /// 自适应卡片底（浅色=近白浅绿/浅橙，深色=深灰卡片）——保留原实现
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
// 注意：玻璃按钮统一使用非交互玻璃（不加 .interactive()）——
// 交互高光是 iOS 26 Liquid Glass 在页面切换/进出动画时产生高光闪烁（过曝）的主要原因，去掉后更稳。
// 玻璃按钮必须加 .contentShape(Rectangle())——玻璃视图会收缩 Button 命中区域，
// 不加会导致按钮点不中（BatteryInsight 已验证的写法）。
// 页面内容（卡片/按钮/胶囊）一律用普通材质（MaterialCard / 纯色 / .quaternary / 系统语义色），
// 不做液态玻璃——玻璃在列表/输入页存在点击命中异常与切换闪烁问题。
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

/// 圆形玻璃返回按钮（官方 Liquid Glass，非交互玻璃，避免切换动画高光闪烁）
/// 注意：必须带 .contentShape(Rectangle())，否则玻璃视图收缩命中区域导致点不中
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
                .glassEffect(.regular, in: .circle)
                .contentShape(Rectangle())
        }
    }
}

/// 液态玻璃卡片（官方 Liquid Glass 容器）——保留玻璃场景使用
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
    }
}

/// 普通磨砂卡片（BatteryInsight 记录卡同款写法）：
/// ultraThinMaterial 微透明白底 + 系统分隔线细描边；深浅模式自适应、通透不显黑。
/// 无液态玻璃高光——避免页面切换闪烁与点击命中异常。
/// 用于物品相关页面（主页卡片 / 详情页信息卡 / 编辑页板块 / 设置页卡片）。
struct MaterialCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
            }
    }
}

/// 胶囊主按钮（官方 Liquid Glass，tint 上色，非交互玻璃避免闪烁）
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
                .glassEffect(.regular.tint(tint), in: .capsule)
                .contentShape(Rectangle())
        }
    }
}

/// 纯色胶囊按钮（非液态玻璃）：纯色底 + 白字，用于详情页等二级页面
struct SolidCapsuleButton: View {
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
                .background(Capsule().fill(tint))
        }
    }
}

/// 状态胶囊标签（普通材质，非液态玻璃）：.quaternary 系统灰底（BatteryInsight 徽章写法），稳定不闪
struct StatusCapsule: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
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

/// 纯色 + 号胶囊按钮（主页/区域页顶栏右上角，参考「有余」布局：+ 独立于 tab 栏）
struct SolidAddCapsule: View {
    var tint: Color = Color(red: 0.36, green: 0.62, blue: 0.48)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 46, height: 36)
                .background(Capsule().fill(tint))
        }
    }
}
