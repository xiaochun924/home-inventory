import Foundation
import SwiftData

/// 库存物品的品类枚举（便于筛选与统计）
enum Category: String, CaseIterable, Codable, Identifiable {
    case momAndBaby = "母婴"
    case paper = "纸品"
    case washCare = "洗护"
    case food = "食品"
    case household = "日用"
    case other = "其他"

    var id: String { rawValue }
}

/// 物品库存状态
enum StockStatus {
    case attention   // 需关注：即将耗尽或已耗尽
    case sufficient  // 库存充足
    case unopened    // 尚未拆封

    var title: String {
        switch self {
        case .attention: return "需关注"
        case .sufficient: return "充足"
        case .unopened: return "尚未拆封"
        }
    }
}

/// 单个家庭消耗品库存条目
@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""            // 物品名称，如：尿不湿 M
    var brand: String = ""           // 品牌，如：维达
    var categoryRaw: String = Category.other.rawValue // 品类（枚举原始值）
    var location: String = "未指定"   // 存放位置，如：诸暨·1
    var totalStock: Int = 0          // 库存数量（未拆封/可用的件数）
    var inUse: Int = 0               // 使用中数量
    var avgConsumeDays: Int = 5      // 平均消耗天数（每 1 件用完需要多少天）
    var reminderDays: Int = 3        // 提醒规则：剩余天数 ≤ 该值时提醒
    var createdAt: Date = Date()
    var isOpened: Bool = true        // 是否已拆封
    var lastUnpackDate: Date?        // 最近拆封日期

    // 拆封记录（级联删除）
    @Relationship(deleteRule: .cascade, inverse: \UnpackRecord.item)
    var unpackRecords: [UnpackRecord] = []

    // 补货记录（级联删除）
    @Relationship(deleteRule: .cascade, inverse: \RestockRecord.item)
    var restockRecords: [RestockRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        category: Category,
        location: String,
        totalStock: Int,
        inUse: Int = 0,
        avgConsumeDays: Int = 5,
        reminderDays: Int = 3,
        isOpened: Bool = true
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.location = location
        self.totalStock = totalStock
        self.inUse = inUse
        self.avgConsumeDays = max(1, avgConsumeDays)
        self.reminderDays = max(1, reminderDays)
        self.createdAt = Date()
        self.isOpened = isOpened
        self.lastUnpackDate = isOpened ? Date() : nil
    }

    // MARK: - 派生计算属性

    /// 品类
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// 可用库存（含使用中）
    var availableStock: Int { totalStock }

    /// 预计剩余可用天数 = 库存数量 × 平均消耗天数
    var remainingDays: Int {
        totalStock * avgConsumeDays
    }

    /// 预计耗尽日期
    var exhaustionDate: Date {
        Calendar.current.date(byAdding: .day, value: remainingDays, to: Date()) ?? Date()
    }

    /// 是否处于需关注状态
    var needsAttention: Bool {
        totalStock <= 0 || remainingDays <= reminderDays
    }

    /// 拆封进度百分比（0-100）：已拆封且最近有拆封记录
    var unpackProgress: Double {
        guard isOpened else { return 0 }
        // 以当前已消耗比例示意：使用中占比
        let total = totalStock + inUse
        guard total > 0 else { return 100 }
        let used = Double(inUse)
        return min(100, (used / Double(total)) * 100)
    }

    /// 最近一次拆封记录
    var lastUnpackRecord: UnpackRecord? {
        unpackRecords.sorted { $0.date > $1.date }.first
    }

    /// 当前状态
    var status: StockStatus {
        if !isOpened { return .unopened }
        return needsAttention ? .attention : .sufficient
    }

    // MARK: - 操作

    /// 拆封：记录一次拆封并更新使用中数量
    func unpack(quantity: Int) {
        let qty = max(1, quantity)
        totalStock = max(0, totalStock - qty)
        inUse += qty
        isOpened = true
        lastUnpackDate = Date()
    }

    /// 补货：记录一次补货并增加库存
    func restock(quantity: Int) {
        let qty = max(1, quantity)
        totalStock += qty
    }
}
