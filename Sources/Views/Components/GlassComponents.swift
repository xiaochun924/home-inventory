import SwiftUI

/// ================= 液态玻璃悬浮顶栏（全局统一规范） =================
/// 规范：纯透明导航栏；左上角圆形玻璃返回按钮；中间悬浮玻璃胶囊标题；
/// 完全隐藏系统导航栏；不加白色蒙皮 / 磨砂遮挡。
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
        ZStack {
            // 中间悬浮玻璃胶囊标题
            HStack {
                leading()
                Spacer()
                Capsule()
                    .fill(.white.opacity(0.42))
                    .background(Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1))
                    .frame(height: 40)
                    .overlay(
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.22, green: 0.4, blue: 0.30))
                            .padding(.horizontal, 20)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
                Spacer()
                trailing()
            }
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
    }
}

/// 圆形玻璃返回按钮
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
                .background(
                    Circle()
                        .fill(.white.opacity(0.45))
                        .background(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        }
    }
}

/// 液态玻璃卡片
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(0.42))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 16, y: 6)
            )
    }
}

/// 胶囊主按钮
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
                .background(
                    Capsule()
                        .fill(tint)
                        .shadow(color: tint.opacity(0.4), radius: 12, y: 5)
                )
        }
    }
}

/// 状态胶囊标签
struct StatusCapsule: View {
    let text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}
