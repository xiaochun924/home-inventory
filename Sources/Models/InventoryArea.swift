import Foundation
import SwiftData

/// 管理分区（区域）：如「东阳」「金华」。一个区域对应一个库存管理入口
/// 物品通过 location 字符串归入区域；删除区域不删除物品，仅移除分区入口
@Model
final class InventoryArea {
    @Attribute(.unique) var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
