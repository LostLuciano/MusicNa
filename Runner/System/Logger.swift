import Foundation

/// Centralized logging system for NativeMusicX with performance tracking.
/// Logs are written to both console and a persistent file for debugging.
public class Logger {
    
    static let shared = Logger()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    private let logFileURL: URL
    private let fileQueue = DispatchQueue(label: "com.musicnative.logger", attributes: .concurrent)
    
    private init() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logFileURL = documentsDir.appendingPathComponent("NativeMusicX.log")
        
        // Initialize log file
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
    }
    
    /// Log levels for filtering
    enum Level: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case performance = "PERF"
    }
    
    /// Log a message with optional level
    public func log(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) — \(message)"
        
        // Console output
        print(logMessage)
        
        // File output (async to avoid blocking)
        fileQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let data = (logMessage + "\n").data(using: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: self.logFileURL.path) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
        }
    }
    
    /// Log debug message
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Log info message
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Log warning message
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Log error message
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Log performance metric
    public func performance(_ message: String, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        let durationMs = duration * 1000
        log("\(message) — \(String(format: "%.2f", durationMs))ms", level: .performance, file: file, function: function, line: line)
    }
    
    /// Get log file URL for sharing/debugging
    public func getLogFileURL() -> URL {
        return logFileURL
    }
    
    /// Clear log file
    public func clearLogs() {
        fileQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.logFileURL)
            FileManager.default.createFile(atPath: self.logFileURL.path, contents: nil)
        }
    }
}
