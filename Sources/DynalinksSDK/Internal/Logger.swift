import Foundation
import os.log

/// Log level for Dynalinks SDK
public enum DynalinksLogLevel: Int, Comparable {
    /// No logging
    case none = 0
    /// Only errors
    case error = 1
    /// Warnings and errors
    case warning = 2
    /// Info, warnings, and errors
    case info = 3
    /// All logs including debug
    case debug = 4

    public static func < (lhs: DynalinksLogLevel, rhs: DynalinksLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Internal logger for Dynalinks SDK
final class Logger {
    static var logLevel: DynalinksLogLevel = .error

    private static let osLog = OSLog(subsystem: "com.dynalinks.sdk", category: "Dynalinks")

    static func debug(_ message: @autoclosure () -> String) {
        log(level: .debug, message: message())
    }

    static func info(_ message: @autoclosure () -> String) {
        log(level: .info, message: message())
    }

    static func warning(_ message: @autoclosure () -> String) {
        log(level: .warning, message: message())
    }

    static func error(_ message: @autoclosure () -> String) {
        log(level: .error, message: message())
    }

    private static func log(level: DynalinksLogLevel, message: String) {
        guard level <= logLevel else { return }

        let prefix: String
        let osLogType: OSLogType

        switch level {
        case .none:
            return
        case .error:
            prefix = "ERROR"
            osLogType = .error
        case .warning:
            prefix = "WARN"
            osLogType = .default
        case .info:
            prefix = "INFO"
            osLogType = .info
        case .debug:
            prefix = "DEBUG"
            osLogType = .debug
        }

        let formattedMessage = "[Dynalinks] [\(prefix)] \(message)"

        // Use os_log for system integration
        os_log("%{public}@", log: osLog, type: osLogType, formattedMessage)

        // Also print to console for debugging
        #if DEBUG
        print(formattedMessage)
        #endif
    }
}
