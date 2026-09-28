import Foundation

/// 崩溃日志采集器
/// 未捕获异常 / 崩溃信号自动写入 Documents/CrashLogs/crash_<时间戳>.log
///
/// 实现要点：
///  - 处理器必须是 @convention(c) 闭包（不能捕获上下文），且可在任意线程触发，
///    因此文件写入全部走 POSIX 层（mkdir/open/write/close + NSHomeDirectory），
///    不使用 Bundle.main / FileManager.default / ProcessInfo 等 @MainActor 单例，
///    避免 iOS 26 SDK 下的隔离编译错误。
///  - 日志为「尽力而为」写入：崩溃场景下部分系统调用可能不可用，但不影响 App 正常运行。
enum CrashLogger {
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
            writeCrash(body)
        }

        // 常见崩溃信号
        installSignalHandler(SIGABRT)
        installSignalHandler(SIGSEGV)
        installSignalHandler(SIGBUS)
        installSignalHandler(SIGILL)
        installSignalHandler(SIGFPE)
    }

    private static func installSignalHandler(_ sig: Int32) {
        signal(sig) { code in
            let body = [
                "类型：Signal",
                "信号：\(signalName(code))",
                "",
                "调用栈：",
                Thread.callStackSymbols.joined(separator: "\n")
            ].joined(separator: "\n")
            writeCrash(body)
        }
    }

    private static func signalName(_ code: Int32) -> String {
        switch code {
        case SIGABRT: return "SIGABRT"
        case SIGSEGV: return "SIGSEGV"
        case SIGBUS: return "SIGBUS"
        case SIGILL: return "SIGILL"
        case SIGFPE: return "SIGFPE"
        default: return "信号(\(code))"
        }
    }

    /// 崩溃日志目录：<沙盒>/Documents/CrashLogs（已存在时 mkdir 返回 -1，忽略）
    private static func crashDirPath() -> String {
        let dir = NSHomeDirectory() + "/Documents/CrashLogs"
        _ = dir.withCString { mkdir($0, 0o755) }
        return dir
    }

    /// 追加写入崩溃日志（文件名带时间戳）
    private static func writeCrash(_ body: String) {
        let dir = crashDirPath()
        let ts = Int(Date().timeIntervalSince1970)
        let path = "\(dir)/crash_\(ts).log"
        let content = "═══ Home Inventory 崩溃日志 ═══\n时间：\(Date())\n" + body + "\n"
        let fd = path.withCString { open($0, O_WRONLY | O_CREAT | O_APPEND, 0o644) }
        if fd >= 0 {
            _ = content.withCString { write(fd, $0, strlen($0)) }
            close(fd)
        }
    }
}
