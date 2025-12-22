import Foundation
import os

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
enum DynalinksLogger {
    static var logLevel: DynalinksLogLevel = .error

    private static let logger = os.Logger(subsystem: "com.dynalinks.sdk", category: "Dynalinks")

    static func debug(_ message: @autoclosure () -> String) {
        guard .debug <= logLevel else { return }
        let msg = message()
        logger.debug("\(msg, privacy: .public)")
    }

    static func info(_ message: @autoclosure () -> String) {
        guard .info <= logLevel else { return }
        let msg = message()
        logger.info("\(msg, privacy: .public)")
    }

    static func warning(_ message: @autoclosure () -> String) {
        guard .warning <= logLevel else { return }
        let msg = message()
        logger.warning("\(msg, privacy: .public)")
    }

    static func error(_ message: @autoclosure () -> String) {
        guard .error <= logLevel else { return }
        let msg = message()
        logger.error("\(msg, privacy: .public)")
    }
}
