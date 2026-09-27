import Foundation
import SwiftData

/// 管理分区（区域）：如「东阳」「金华」。一个区域对应一个库存管理入口
/// 物品通过 location 字符串归入区域；删除区域不删除物品，仅移除分区入口
/// sortOrder 控制底部导航中的显示顺序（设置页可上下调整）
@Model
final class InventoryArea {
    @Attribute(.unique) var id: UUID = UUID()
    @Attribute(.unique) var name: String
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(name: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
