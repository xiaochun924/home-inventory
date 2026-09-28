import SwiftUI
import WidgetKit

/// 小组件视图：白底（systemBackground）+ 品牌绿，与主 App 视觉一致
/// 注意：这里用静态 RGB 字面量（与主 App 品牌色常量同值），
/// 不使用 UIColor{...} 动态闭包——iOS 26 异步渲染线程解析动态色会崩溃（历史崩溃根因）
/// 无数据（hasData == false，如自签未保留 App Group）时显示引导态，避免误导性 0
struct InventoryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: InventoryEntry

    var body: some View {
        Group {
            if entry.hasData {
                dataView
            } else {
                emptyStateView
            }
        }
        .containerBackground(for: .widget) {
            // accessory 交给系统绘制；常规尺寸使用与 App 一致的白底
            family == .accessoryCircular ? Color.clear : Color(uiColor: .systemBackground)
        }
    }

    @ViewBuilder
    private var dataView: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .accessoryCircular:
            circularView
        default:
            smallView
        }
    }

    // MARK: - 无数据引导态（App Group 权限缺失或 App 未同步）

    @ViewBuilder
    private var emptyStateView: some View {
        if family == .accessoryCircular {
            Text("–")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.secondary)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 22))
                    .foregroundColor(Color.wBrandGreen)
                Text("库存未同步")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                if family == .systemMedium {
                    Text("安装包需保留 App Group 权限")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "homeinventory://overview"))
        }
    }

    // MARK: - 系统小尺寸：需关注大字 + 库存/使用中

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("库存概览")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.wBrandGreen)
            Spacer(minLength: 10)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(entry.snapshot.attentionCount)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(entry.snapshot.attentionCount > 0 ? .orange : Color.wBrandDeepGreen)
                    .contentTransition(.numericText())
                Text("需关注")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
            statLine("库存", value: entry.snapshot.totalStock)
            statLine("使用中", value: entry.snapshot.totalInUse)
            Spacer(minLength: 6)
            Text("更新于 \(timeText)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .widgetURL(URL(string: "homeinventory://overview"))
    }

    // MARK: - 系统中尺寸：区域库存（左） + 统计（右）

    private var mediumView: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("区域库存")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.wBrandGreen)
                if entry.snapshot.areaSummaries.isEmpty {
                    Text("暂无区域，去 App 添加分区")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(entry.snapshot.areaSummaries.prefix(3)) { area in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.wBrandGreen.opacity(0.25))
                                .frame(width: 6, height: 6)
                            Text(area.name)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(area.count) 件")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    if entry.snapshot.areaSummaries.count > 3 {
                        Text("等 \(entry.snapshot.areaSummaries.count) 个区域")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            Divider().opacity(0.4)
            VStack(alignment: .trailing, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.attentionCount)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(entry.snapshot.attentionCount > 0 ? .orange : Color.wBrandDeepGreen)
                        .contentTransition(.numericText())
                    Text("需关注")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                statLine("库存", value: entry.snapshot.totalStock)
                statLine("使用中", value: entry.snapshot.totalInUse)
                Spacer(minLength: 0)
                Text("更新于 \(timeText)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .widgetURL(URL(string: "homeinventory://overview"))
    }

    // MARK: - 锁屏圆形：剩余库存比例

    private var circularView: some View {
        let s = entry.snapshot
        let used = Double(s.totalInUse)
        let total = Double(s.totalStock + s.totalInUse)
        let progress: Double = total > 0 ? min(max(used / total, 0), 1) : 0
        return Gauge(value: progress) {
            Text("库存")
        } currentValueLabel: {
            Text("\(s.totalStock)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Color.wBrandGreen)
    }

    // MARK: - 小组件

    private func statLine(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold))
                .contentTransition(.numericText())
        }
    }

    private var timeText: String {
        entry.snapshot.updatedAt.formatted(date: .omitted, time: .shortened)
    }
}

/// 小组件品牌色（与 App 端 brandGreen/brandDeepGreen 同值，静态 RGB 线程安全）
private extension Color {
    static let wBrandGreen = Color(red: 0.36, green: 0.62, blue: 0.48)
    static let wBrandDeepGreen = Color(red: 0.28, green: 0.52, blue: 0.40)
}
