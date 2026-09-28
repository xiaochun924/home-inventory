import Foundation

/// 崩溃日志采集器
/// 安装未捕获异常与常见崩溃信号处理器，崩溃时自动把信息写入应用本地
/// Documents/CrashLogs/ 目录（文件名带时间戳，最多保留最近 20 份）。
/// 日志可通过 iOS「文件」App → 我的 iPhone → Home Inventory → CrashLogs 查看/导出，
/// 闪退后把日志文件发出来即可定位崩溃点。
///
/// 注意：信号处理器内只能调用静态方法（@convention(c) 不允许捕获上下文），
/// 写入过程为「尽力而为」，崩溃场景下部分系统调用可能不可用，但不影响 App 正常运行。
enum CrashLogger {
    /// 崩溃日志目录：Documents/CrashLogs
    static let directoryURL: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("CrashLogs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    /// 信号名对照表（供信号处理器读取，避免闭包捕获局部变量）
    private static let signalNames: [Int32: String] = [
        SIGABRT: "SIGABRT",
        SIGSEGV: "SIGSEGV",
        SIGBUS: "SIGBUS",
        SIGILL: "SIGILL",
        SIGFPE: "SIGFPE"
    ]

    /// 在 App 启动时调用一次
    static func install() {
        // 未捕获的 NSException（Swift fatalError / force unwrap 等）
        NSSetUncaughtExceptionHandler { exception in
            let body = [
                "类型：NSException",
                "异常：\(exception.name.rawValue)",
                "原因：\(exception.reason ?? "未知")",
                "",
                "调用栈：",
                exception.callStackSymbols.joined(separator: "\n")
            ].joined(separator: "\n")
            write(body)
        }

        // 常见崩溃信号
        installSignal(SIGABRT)
        installSignal(SIGSEGV)
        installSignal(SIGBUS)
        installSignal(SIGILL)
        installSignal(SIGFPE)
    }

    private static func installSignal(_ sig: Int32) {
        signal(sig) { code in
            let name = signalNames[code] ?? "信号(\(code))"
            let body = [
                "类型：Signal",
                "信号：\(name)",
                "",
                "调用栈：",
                Thread.callStackSymbols.joined(separator: "\n")
            ].joined(separator: "\n")
            write(body)
        }
    }

    /// 组装并写入日志文件（带时间戳文件名，保留最近 20 份）
    private static func write(_ body: String) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let header = [
            "═══ Home Inventory 崩溃日志 ═══",
            "时间：\(Date())",
            "App 版本：\(appVersion)",
            "系统版本：iOS \(osVersion)",
            "==================================",
            body
        ].joined(separator: "\n")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "crash_\(formatter.string(from: Date())).log"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? header.write(to: fileURL, atomically: true, encoding: .utf8)

        // 只保留最近 20 份日志，避免无限堆积
        let files = (try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        let logs = files.filter { $0.pathExtension == "log" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        if logs.count > 20 {
            for f in logs.dropFirst(20) {
                try? FileManager.default.removeItem(at: f)
            }
        }
    }
}
