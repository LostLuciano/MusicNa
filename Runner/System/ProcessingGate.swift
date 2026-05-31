import Foundation

/// ProcessingGate ensures only one heavy audio processing operation runs at a time.
/// Prevents CPU overload by serializing: separation → chord/beat/export/record
public class ProcessingGate {
    
    static let shared = ProcessingGate()
    
    private let lock = NSLock()
    private var activeOperation: ProcessingOperation? = nil
    private var waitingQueue: [ProcessingOperation] = []
    
    public enum ProcessingOperation: Equatable {
        case separation
        case chordDetection
        case beatDetection
        case export
        case recording
        case analysis
        
        var priority: Int {
            switch self {
            case .separation: return 100
            case .recording: return 90
            case .export: return 80
            case .chordDetection: return 50
            case .beatDetection: return 50
            case .analysis: return 40
            }
        }
        
        var description: String {
            switch self {
            case .separation: return "Stem Separation"
            case .chordDetection: return "Chord Detection"
            case .beatDetection: return "Beat Detection"
            case .export: return "Export"
            case .recording: return "Recording"
            case .analysis: return "Analysis"
            }
        }
    }
    
    private init() {}
    
    /// Request to start a processing operation.
    /// Returns true if operation can start immediately, false if queued.
    public func requestOperation(_ operation: ProcessingOperation) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // If no active operation, start immediately
        if activeOperation == nil {
            activeOperation = operation
            Logger.shared.info("🟢 Processing gate OPENED: \(operation.description)")
            return true
        }
        
        // If same operation already running, reject
        if activeOperation == operation {
            Logger.shared.warning("⚠️ \(operation.description) already in progress, rejecting duplicate request")
            return false
        }
        
        // Queue the operation
        waitingQueue.append(operation)
        Logger.shared.info("⏳ \(operation.description) queued (position: \(waitingQueue.count))")
        return false
    }
    
    /// Check if a specific operation is currently active
    public func isOperationActive(_ operation: ProcessingOperation) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeOperation == operation
    }
    
    /// Check if any operation is currently active
    public func isAnyOperationActive() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeOperation != nil
    }
    
    /// Get current active operation
    public func getActiveOperation() -> ProcessingOperation? {
        lock.lock()
        defer { lock.unlock() }
        return activeOperation
    }
    
    /// Get queue status
    public func getQueueStatus() -> (active: ProcessingOperation?, queued: [ProcessingOperation]) {
        lock.lock()
        defer { lock.unlock() }
        return (activeOperation, waitingQueue)
    }
    
    /// Mark operation as complete and process next in queue
    public func completeOperation(_ operation: ProcessingOperation) {
        lock.lock()
        defer { lock.unlock() }
        
        guard activeOperation == operation else {
            Logger.shared.warning("⚠️ Attempted to complete \(operation.description) but it's not active")
            return
        }
        
        activeOperation = nil
        Logger.shared.info("🔴 Processing gate CLOSED: \(operation.description) completed")
        
        // Process next in queue (sorted by priority)
        if !waitingQueue.isEmpty {
            waitingQueue.sort { $0.priority > $1.priority }
            let nextOperation = waitingQueue.removeFirst()
            activeOperation = nextOperation
            Logger.shared.info("🟢 Processing gate OPENED: \(nextOperation.description) (from queue)")
        }
    }
    
    /// Cancel all queued operations
    public func cancelQueue() {
        lock.lock()
        defer { lock.unlock() }
        
        let cancelledCount = waitingQueue.count
        waitingQueue.removeAll()
        Logger.shared.info("❌ Cancelled \(cancelledCount) queued operations")
    }
    
    /// Wait for gate to be available (blocking, use in async context)
    public func waitForAvailability(timeout: TimeInterval = 300) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            lock.lock()
            let isAvailable = activeOperation == nil
            lock.unlock()
            
            if isAvailable {
                return true
            }
            
            // Sleep briefly before checking again
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        Logger.shared.warning("⏱️ Processing gate timeout after \(timeout)s")
        return false
    }
}
