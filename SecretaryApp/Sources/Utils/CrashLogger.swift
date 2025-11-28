import Foundation
import AppKit

enum CrashLogger {
    static func install() {
        NSSetUncaughtExceptionHandler { exception in
            let reason = exception.reason ?? "Unknown"
            let symbols = exception.callStackSymbols.joined(separator: "\n")
            log("Uncaught exception: \(reason)\n\(symbols)")
        }
        
        let signals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]
        for sig in signals {
            signal(sig) { sig in
                log("Captured fatal signal: \(sig)")
                _Exit(sig)
            }
        }
    }
}
