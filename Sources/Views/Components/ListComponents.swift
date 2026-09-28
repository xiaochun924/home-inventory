import SwiftUI

/// 概览统计列（主页/区域页共用）：图标 + 大数字 + 标签
struct StatColumn: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
            Text("\(value)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

/// 概览统计列之间的竖分隔线
struct StatDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.adaptiveSeparator)
            .frame(width: 1, height: 34)
    }
}

/// 搜索框（主页/区域页共用）
struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索物品", text: $text)
                .font(.system(size: 15))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.adaptiveCardFill)
                .background(RoundedRectangle(cornerRadius: 14).stroke(Color.adaptiveCardStroke, lineWidth: 1))
        )
    }
}

/// 分区标题 + 计数徽章（主页/区域页共用）
struct SectionHeader: View {
    let title: String
    let count: Int
    var tint: Color = Color.brandGreen

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.adaptiveTextGreen)
            Spacer()
            Text("\(count) 件")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(tint))
        }
        .padding(.top, 6)
    }
}

/// 空状态卡（主页/区域页共用）：图标 + 提示文案 + 可选「去添加」按钮
struct EmptyCard: View {
    let icon: String
    let text: String
    var addButtonTitle: String? = nil
    var addAction: (() -> Void)? = nil

    var body: some View {
        HomeCard {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                if let title = addButtonTitle, let action = addAction {
                    Button(action: action) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.brandGreen))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

/// 页脚提示（主页/区域页共用）
struct FooterHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }
}
