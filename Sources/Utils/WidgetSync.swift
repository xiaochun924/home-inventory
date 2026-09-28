import Foundation
import SwiftData

/// App 侧：库存数据变化后，把摘要同步给小组件
/// （写 App Group UserDefaults + 主动刷新小组件时间线）
enum WidgetSync {
    /// 由 RootView 的数据指纹变化触发（主线程）
    /// 汇总口径与主页一致：需关注 = needsAttention；区域件数 = location == 区域名
    @MainActor
    static func sync(items: [InventoryItem], areas: [InventoryArea]) {
        let snapshot = WidgetSnapshot(
            totalItems: items.count,
            totalStock: items.reduce(0) { $0 + $1.totalStock },
            totalInUse: items.reduce(0) { $0 + $1.inUse },
            attentionCount: items.filter { $0.needsAttention }.count,
            areaSummaries: areas.map { area in
                WidgetSnapshot.AreaSummary(
                    name: area.name,
                    count: items.filter { $0.location == area.name }.count
                )
            },
            updatedAt: Date()
        )
        WidgetSnapshotStore.write(snapshot)
    }
}
