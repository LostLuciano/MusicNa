import Foundation
import os.log

/// PerformanceGuard monitors thermal state, memory, and processing times.
/// Prevents CPU overload by tracking metrics and throttling if needed.
public class PerformanceGuard {
    
    static let shared = PerformanceGuard()
    
    private let lock = NSLock()
    
    // Thermal state monitoring
    private var thermalState: ProcessInfo.ThermalState = .nominal
    private var thermalStateObserver: NSObjectProtocol?
    
    // Memory tracking
    private var peakMemoryUsage: UInt64 = 0
    private var currentMemoryUsage: UInt64 = 0
    
    // Processing time tracking
    private var processingMetrics: [String: ProcessingMetric] = [:]
    
    public struct ProcessingMetric {
        var operationName: String
        var startTime: Date
        var estimatedDuration: TimeInterval = 0
        var checkpoints: [(name: String, duration: TimeInterval)] = []
        
        var elapsedTime: TimeInterval {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    // Thresholds
    private let thermalThreshold: ProcessInfo.ThermalState = .critical
    private let memoryWarningThreshold: UInt64 = 800 * 1024 * 1024 // 800 MB
    private let maxProcessingTime: TimeInterval = 600 // 10 minutes
    
    private init() {
        setupThermalMonitoring()
        setupMemoryWarningNotification()
    }
    
    // MARK: - Thermal State Monitoring
    
    private func setupThermalMonitoring() {
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalState()
        }
        updateThermalState()
    }
    
    private func updateThermalState() {
        lock.lock()
        defer { lock.unlock() }
        
        let newState = ProcessInfo.processInfo.thermalState
        if newState != thermalState {
            thermalState = newState
            logThermalStateChange(newState)
        }
    }
    
    private func logThermalStateChange(_ state: ProcessInfo.ThermalState) {
        let stateString: String
        switch state {
        case .nominal:
            stateString = "🟢 NOMINAL"
        case .fair:
            stateString = "🟡 FAIR"
        case .serious:
            stateString = "🟠 SERIOUS"
        case .critical:
            stateString = "🔴 CRITICAL"
        @unknown default:
            stateString = "❓ UNKNOWN"
        }
        Logger.shared.warning("Thermal state changed to: \(stateString)")
    }
    
    public func getThermalState() -> ProcessInfo.ThermalState {
        lock.lock()
        defer { lock.unlock() }
        return thermalState
    }
    
    public func isThermalThrottling() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return thermalState.rawValue >= thermalThreshold.rawValue
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryWarningNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        Logger.shared.warning("⚠️ Memory warning received from system")
        updateMemoryUsage()
    }
    
    private func updateMemoryUsage() {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &count
                )
            }
        }
        
        guard kerr == KERN_SUCCESS else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        currentMemoryUsage = UInt64(info.phys_footprint)
        if currentMemoryUsage > peakMemoryUsage {
            peakMemoryUsage = currentMemoryUsage
        }
        
        if currentMemoryUsage > memoryWarningThreshold {
            Logger.shared.warning("⚠️ High memory usage: \(formatBytes(currentMemoryUsage))")
        }
    }
    
    public func getCurrentMemoryUsage() -> UInt64 {
        updateMemoryUsage()
        lock.lock()
        defer { lock.unlock() }
        return currentMemoryUsage
    }
    
    public func getPeakMemoryUsage() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return peakMemoryUsage
    }
    
    public func getMemoryUsageString() -> String {
        let current = getCurrentMemoryUsage()
        let peak = getPeakMemoryUsage()
        return "Current: \(formatBytes(current)) / Peak: \(formatBytes(peak))"
    }
    
    // MARK: - Processing Time Tracking
    
    public func startOperation(_ name: String, estimatedDuration: TimeInterval = 0) {
        lock.lock()
        defer { lock.unlock() }
        
        let metric = ProcessingMetric(
            operationName: name,
            startTime: Date(),
            estimatedDuration: estimatedDuration
        )
        processingMetrics[name] = metric
        Logger.shared.info("⏱️ Started: \(name)")
    }
    
    public func addCheckpoint(_ operationName: String, checkpoint: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard var metric = processingMetrics[operationName] else {
            Logger.shared.warning("⚠️ Checkpoint for unknown operation: \(operationName)")
            return
        }
        
        let duration = metric.elapsedTime
        metric.checkpoints.append((checkpoint, duration))
        processingMetrics[operationName] = metric
        
        Logger.shared.performance("\(operationName) → \(checkpoint)", duration: duration)
    }
    
    public func endOperation(_ name: String) -> ProcessingMetric? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let metric = processingMetrics.removeValue(forKey: name) else {
            Logger.shared.warning("⚠️ End operation for unknown: \(name)")
            return nil
        }
        
        let totalDuration = metric.elapsedTime
        Logger.shared.performance("✅ Completed: \(name)", duration: totalDuration)
        
        // Log all checkpoints
        for (checkpoint, duration) in metric.checkpoints {
            Logger.shared.debug("  └─ \(checkpoint): \(String(format: "%.2f", duration * 1000))ms")
        }
        
        return metric
    }
    
    public func getOperationStatus(_ name: String) -> ProcessingMetric? {
        lock.lock()
        defer { lock.unlock() }
        return processingMetrics[name]
    }
    
    public func getAllOperations() -> [String: ProcessingMetric] {
        lock.lock()
        defer { lock.unlock() }
        return processingMetrics
    }
    
    // MARK: - Throttling Decision
    
    public func shouldThrottle() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // Throttle if thermal state is serious or critical
        if thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue {
            return true
        }
        
        // Throttle if memory usage is high
        if currentMemoryUsage > memoryWarningThreshold {
            return true
        }
        
        return false
    }
    
    public func getThrottleReason() -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        if thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue {
            return "Thermal state: \(thermalState)"
        }
        
        if currentMemoryUsage > memoryWarningThreshold {
            return "High memory: \(formatBytes(currentMemoryUsage))"
        }
        
        return nil
    }
    
    // MARK: - Utilities
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    public func getPerformanceReport() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        var report = "=== Performance Report ===\n"
        report += "Thermal State: \(thermalState)\n"
        report += "Memory: \(getMemoryUsageString())\n"
        report += "Active Operations: \(processingMetrics.count)\n"
        
        for (name, metric) in processingMetrics {
            report += "  • \(name): \(String(format: "%.2f", metric.elapsedTime))s\n"
        }
        
        return report
    }
    
    deinit {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
