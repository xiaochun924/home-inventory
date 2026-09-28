import WidgetKit
import SwiftUI

/// Home Inventory 小组件：库存概览
/// 支持三种尺寸：系统小（需关注 + 库存/使用中）、系统中（区域库存 + 统计）、锁屏圆形（剩余库存比例）
/// 数据来自 App 同步的 WidgetSnapshot（App Group UserDefaults），App 数据变化时主动刷新时间线
@main
struct InventoryWidgetBundle: WidgetBundle {
    var body: some Widget {
        InventoryOverviewWidget()
    }
}

struct InventoryOverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InventoryOverviewWidget", provider: InventoryTimelineProvider()) { entry in
            InventoryWidgetView(entry: entry)
        }
        .configurationDisplayName("库存概览")
        .description("快速查看需关注物品与各区域库存数量")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

/// 时间线条目：携带最新摘要快照
struct InventoryEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// 时间线提供者：读取 App 同步的摘要；App 内数据变化时通过 WidgetCenter 主动刷新
struct InventoryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> InventoryEntry {
        InventoryEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (InventoryEntry) -> Void) {
        completion(InventoryEntry(date: Date(), snapshot: WidgetSnapshotStore.current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InventoryEntry>) -> Void) {
        let entry = InventoryEntry(date: Date(), snapshot: WidgetSnapshotStore.current())
        // 每 15 分钟重算一次；App 内数据变化会主动刷新，无需过密轮询
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
