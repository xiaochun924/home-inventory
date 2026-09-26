import SwiftUI

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
            HStack {
                leading()
                Spacer()
                // 中间悬浮玻璃胶囊标题（官方 Liquid Glass）
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.22, green: 0.4, blue: 0.30))
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .glassEffect(.clear, in: .capsule)
                Spacer()
                trailing()
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

/// 状态胶囊标签（官方 Liquid Glass）
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
