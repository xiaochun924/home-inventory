import Foundation
import WidgetKit

/// 小组件与 App 共享的库存摘要快照（Codable，经 App Group UserDefaults 传输）
/// App 在库存数据变化后写入，Widget 时间线读取——避免跨进程直接读写 SwiftData 文件
/// （SwiftData/Core Data 文件由主 App 进程持有，多进程直接访问有锁竞争与损坏风险）
struct WidgetSnapshot: Codable, Equatable {
    var totalItems: Int
    var totalStock: Int
    var totalInUse: Int
    var attentionCount: Int
    var areaSummaries: [AreaSummary]
    var updatedAt: Date

    /// 区域库存摘要（按 sortOrder 排序后传入）
    struct AreaSummary: Codable, Equatable, Identifiable {
        var name: String
        var count: Int
        var id: String { name }
    }

    /// 占位快照：仅用于 Widget 预览（placeholder）；真实无数据场景由 hasData 区分并显示引导态
    static let placeholder = WidgetSnapshot(
        totalItems: 0,
        totalStock: 0,
        totalInUse: 0,
        attentionCount: 0,
        areaSummaries: [],
        updatedAt: Date()
    )
}

/// 摘要读写：App 与 Widget 两个进程共用同一 App Group 容器
/// 注意：App Group 依赖签名 entitlement。若安装包未保留 App Group（部分自签工具会剥离），
/// UserDefaults(suiteName:) 返回 nil，写入与读取均失败——这是 iOS 沙盒硬限制，代码无法绕过。
enum WidgetSnapshotStore {
    /// App Group 标识：与 App/Widget 的 entitlements 保持一致
    static let groupID = "group.com.xiaochun924.HomeInventory"
    static let key = "widgetSnapshot"

    /// 是否已有 App 同步的数据（false = 无 App Group 权限 或 App 从未同步过）
    static var hasData: Bool {
        UserDefaults(suiteName: groupID)?.data(forKey: key) != nil
    }

    /// 读取当前摘要；尚无数据时返回占位（空数据）
    static func current() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: groupID)?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }

    /// 写入摘要并主动刷新小组件时间线（App 主线程调用）
    @MainActor
    static func write(_ snapshot: WidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults(suiteName: groupID)?.set(data, forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
