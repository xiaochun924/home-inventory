import Foundation

/// 格式化与日期计算工具
enum Format {
    /// 相对天数：X 天前 / X 天后 / 今天
    /// 按自然日（startOfDay）计算：只要跨了日历日即算 1 天，避免昨晚的操作今晨仍显示为「今天」
    /// Calendar.current 为系统缓存实例，线程安全，无需手动缓存
    static func relativeDays(from date: Date, to now: Date = Date()) -> String {
        let cal = Calendar.current
        let startOfDate = cal.startOfDay(for: date)
        let startOfNow = cal.startOfDay(for: now)
        let days = cal.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
        if days == 0 { return "今天" }
        if days > 0 { return "\(days)天前" }
        return "\(-days)天后"
    }

    /// 短日期：M月d日
    /// 用 Date.FormatStyle（值类型、线程安全），替代每次新建 DateFormatter 的高频开销
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits))
    }
}

/// 消耗预测结果
struct ConsumptionPrediction {
    let remainingPack: Int      // 今日剩余件数
    let daysUntilExhausted: Int // 预计 N 天后耗尽
    let exhaustionDate: Date    // 预计耗尽日期
}
