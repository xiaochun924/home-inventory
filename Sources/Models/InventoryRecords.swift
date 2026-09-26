import Foundation
import SwiftData

/// 一次拆封记录
@Model
final class UnpackRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var quantity: Int = 0

    var item: InventoryItem?

    init(id: UUID = UUID(), date: Date = Date(), quantity: Int) {
        self.id = id
        self.date = date
        self.quantity = quantity
    }
}

/// 一次补货记录
@Model
final class RestockRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var quantity: Int = 0

    var item: InventoryItem?

    init(id: UUID = UUID(), date: Date = Date(), quantity: Int) {
        self.id = id
        self.date = date
        self.quantity = quantity
    }
}
