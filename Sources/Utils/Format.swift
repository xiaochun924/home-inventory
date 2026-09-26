import Foundation

/// 格式化与日期计算工具
enum Format {
    /// 相对天数：X 天前 / X 天后 / 今天
    static func relativeDays(from date: Date, to now: Date = Date()) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
        if days == 0 { return "今天" }
        if days > 0 { return "\(days)天前" }
        return "\(-days)天后"
    }

    /// 短日期：M月d日
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

/// 消耗预测结果
struct ConsumptionPrediction {
    let remainingPack: Int      // 今日剩余件数
    let daysUntilExhausted: Int // 预计 N 天后耗尽
    let exhaustionDate: Date    // 预计耗尽日期
}
