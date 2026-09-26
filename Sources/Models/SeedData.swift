import Foundation
import SwiftData

/// 首次启动播种示例数据，便于用户快速了解界面效果
enum SeedData {

    static func installIfNeeded(_ container: ModelContainer) {
        let context = container.mainContext
        // 已存在数据则跳过
        if (try? context.fetchCount(FetchDescriptor<InventoryItem>())) ?? 0 > 0 {
            return
        }
        let items: [InventoryItem] = [
            InventoryItem(name: "尿不湿 M", category: .momAndBaby, location: "诸暨·1", totalStock: 37, inUse: 2, avgConsumeDays: 3, reminderDays: 3),
            InventoryItem(name: "房间棉柔巾", category: .paper, location: "诸暨·1", totalStock: 7, inUse: 1, avgConsumeDays: 5, reminderDays: 3),
            InventoryItem(name: "奶粉", category: .momAndBaby, location: "东阳·1", totalStock: 6, inUse: 2, avgConsumeDays: 4, reminderDays: 3),
            InventoryItem(name: "乳霜纸", category: .washCare, location: "诸暨·1", totalStock: 7, inUse: 1, avgConsumeDays: 7, reminderDays: 3),
            InventoryItem(name: "货架棉柔巾", category: .paper, location: "诸暨·1", totalStock: 12, inUse: 0, avgConsumeDays: 6, reminderDays: 3, isOpened: false),
            InventoryItem(name: "湿纸巾", category: .washCare, location: "东阳·2", totalStock: 2, inUse: 1, avgConsumeDays: 4, reminderDays: 3)
        ]
        for item in items {
            context.insert(item)
        }
        try? context.save()
    }
}
