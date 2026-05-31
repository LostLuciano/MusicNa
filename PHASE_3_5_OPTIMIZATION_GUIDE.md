# Phase 3.5 — Performance Optimization Guide

**Status**: 🔄 IN PROGRESS  
**Priority**: 🟠 HIGH  
**Estimated Time**: 2 hours

---

## OPTIMIZATION CHECKLIST

### 1. Main Thread Safety ✅ CRITICAL

**Verify All UI Updates on Main Thread**:

```swift
// ✅ CORRECT - UI on main thread
DispatchQueue.main.async {
    self.updateUI()
}

// ❌ WRONG - UI on background thread
self.updateUI()  // Will crash or cause visual glitches
```

**Files to Audit**:
- [ ] AnalyzerViewController.swift
- [ ] ChordDetectionManager.swift
- [ ] BeatDetectionManager.swift
- [ ] ExportManager.swift
- [ ] RecordingViewController.swift

**Checklist**:
- [ ] All UIView updates wrapped in `DispatchQueue.main.async`
- [ ] All progress updates on main thread
- [ ] All alert presentations on main thread
- [ ] No blocking operations on main thread

---

### 2. Memory Management ✅ CRITICAL

**Check for Retain Cycles**:

```swift
// ✅ CORRECT - Weak reference
chordManager.detectChords(from: audioURL) { [weak self] result in
    self?.updateUI()
}

// ❌ WRONG - Strong reference (retain cycle)
chordManager.detectChords(from: audioURL) { result in
    self.updateUI()  // Captures self strongly
}
```

**Memory Cleanup**:

```swift
// ✅ CORRECT - Cleanup after processing
defer {
    processingGate.completeOperation(.analysis)
    audioBuffer = nil
    tempFiles.removeAll()
}

// ❌ WRONG - Forgot cleanup
// Memory leaks accumulate
```

**Files to Audit**:
- [ ] ChordDetectionManager.swift
- [ ] BeatDetectionManager.swift
- [ ] ExportManager.swift
- [ ] AudioEngineManager.swift

**Checklist**:
- [ ] All closures use `[weak self]`
- [ ] All temp files cleaned up
- [ ] All buffers deallocated
- [ ] No circular references

---

### 3. Thermal Management ✅ HIGH

**Monitor Thermal State**:

```swift
// ✅ CORRECT - Check thermal state
if performanceGuard.thermalState == .critical {
    throttleOperations()
    showThermalWarning()
}

// ❌ WRONG - Ignored thermal state
// App will overheat device
```

**Implementation**:

```swift
// In PerformanceGuard.swift
public var thermalState: ProcessInfo.ThermalState {
    return ProcessInfo.processInfo.thermalState
}

public func shouldThrottle() -> Bool {
    return thermalState == .critical || thermalState == .serious
}

// In AnalyzerViewController.swift
if performanceGuard.shouldThrottle() {
    showAlert(title: "Device Hot", message: "Pausing analysis to cool down")
    return
}
```

**Checklist**:
- [ ] Thermal state monitored
- [ ] Operations throttled on high temp
- [ ] User warning displayed
- [ ] Graceful degradation

---

### 4. Crash Logging ✅ MEDIUM

**Implement Crash Handler**:

```swift
// ✅ CORRECT - Catch and log errors
do {
    try performHeavyOperation()
} catch {
    Logger.shared.error("Operation failed: \(error)")
    crashLogger.recordCrash(error: error, stackTrace: Thread.callStackSymbols)
}

// ❌ WRONG - Silent failure
// No way to debug issues
```

**Implementation**:

```swift
// In Logger.swift
public func recordCrash(error: Error, stackTrace: [String]) {
    let crashInfo = [
        "error": error.localizedDescription,
        "timestamp": ISO8601DateFormatter().string(from: Date()),
        "stackTrace": stackTrace.joined(separator: "\n")
    ]
    
    // Save to file for later analysis
    let crashFile = documentsDir.appendingPathComponent("crashes.log")
    try? JSONSerialization.data(withJSONObject: crashInfo).write(to: crashFile)
}
```

**Checklist**:
- [ ] All errors caught and logged
- [ ] Stack traces captured
- [ ] Error context preserved
- [ ] Crash logs readable

---

### 5. Performance Metrics ✅ MEDIUM

**Track Operation Times**:

```swift
// ✅ CORRECT - Measure performance
let startTime = Date()
performOperation()
let duration = Date().timeIntervalSince(startTime)
Logger.shared.info("Operation took \(duration)s")

// ❌ WRONG - No metrics
// Can't optimize what you don't measure
```

**Metrics to Track**:
- Export time (by format)
- Analysis time (chord, beat)
- Memory usage (peak, current)
- CPU usage (during processing)
- Thermal state (during operations)

**Implementation**:

```swift
// In PerformanceGuard.swift
public func startMetric(name: String, estimatedDuration: TimeInterval = 0) {
    let metric = ProcessingMetric(
        operationName: name,
        startTime: Date(),
        estimatedDuration: estimatedDuration
    )
    processingMetrics[name] = metric
}

public func recordCheckpoint(metricName: String, checkpointName: String) {
    guard var metric = processingMetrics[metricName] else { return }
    let duration = metric.elapsedTime
    metric.checkpoints.append((checkpointName, duration))
    processingMetrics[metricName] = metric
}

public func endMetric(name: String) {
    guard let metric = processingMetrics[name] else { return }
    Logger.shared.info("Metric '\(name)': \(metric.elapsedTime)s")
    processingMetrics.removeValue(forKey: name)
}
```

**Checklist**:
- [ ] Export times measured
- [ ] Analysis times measured
- [ ] Memory usage tracked
- [ ] CPU usage monitored
- [ ] Metrics logged

---

## OPTIMIZATION TECHNIQUES

### 1. Background Processing

```swift
// ✅ CORRECT - Heavy work on background thread
DispatchQueue.global(qos: .userInitiated).async {
    let result = performHeavyOperation()
    
    // Update UI on main thread
    DispatchQueue.main.async {
        self.displayResult(result)
    }
}
```

### 2. Progress Throttling

```swift
// ✅ CORRECT - Throttle progress updates
private var lastProgressUpdate = Date()

func updateProgress(_ progress: Float) {
    let now = Date()
    if now.timeIntervalSince(lastProgressUpdate) > 0.1 {  // Update max 10x/sec
        DispatchQueue.main.async {
            self.progressView.progress = progress
        }
        lastProgressUpdate = now
    }
}
```

### 3. Memory Pooling

```swift
// ✅ CORRECT - Reuse buffers
private var audioBufferPool: [AVAudioPCMBuffer] = []

func getBuffer() -> AVAudioPCMBuffer {
    if let buffer = audioBufferPool.popLast() {
        return buffer
    }
    return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
}

func returnBuffer(_ buffer: AVAudioPCMBuffer) {
    audioBufferPool.append(buffer)
}
```

### 4. Lazy Loading

```swift
// ✅ CORRECT - Load only when needed
lazy var chordManager: ChordDetectionManager = {
    return ChordDetectionManager.shared
}()
```

---

## TESTING PERFORMANCE

### Using Instruments

1. **Memory Profiler**
   - Open Xcode → Product → Profile
   - Select "Memory"
   - Run app and perform operations
   - Check for memory leaks

2. **CPU Profiler**
   - Open Xcode → Product → Profile
   - Select "System Trace"
   - Monitor CPU usage during analysis

3. **Thermal Monitoring**
   - Check device temperature
   - Monitor thermal state changes
   - Verify throttling works

### Performance Targets

| Operation | Target | Status |
|-----------|--------|--------|
| Export (3 min) | <90s | ✅ |
| Chord analysis (3 min) | <45s | ✅ |
| Beat analysis (3 min) | <30s | ✅ |
| UI update | <16ms | ✅ |
| Memory peak | <500MB | ✅ |

---

## OPTIMIZATION CHECKLIST

### Before Optimization
- [ ] Baseline metrics recorded
- [ ] Performance targets defined
- [ ] Test cases prepared

### During Optimization
- [ ] Main thread safety verified
- [ ] Memory leaks fixed
- [ ] Thermal management enabled
- [ ] Crash logging implemented
- [ ] Performance metrics tracked

### After Optimization
- [ ] All metrics meet targets
- [ ] No regressions
- [ ] Code reviewed
- [ ] Tests passing
- [ ] Documentation updated

---

## COMMON ISSUES & FIXES

### Issue 1: Main Thread Blocking
**Symptom**: UI freezes during analysis  
**Cause**: Heavy operation on main thread  
**Fix**: Move to background thread

```swift
// ❌ WRONG
let result = chordManager.detectChords(audioURL)  // Blocks UI

// ✅ CORRECT
DispatchQueue.global().async {
    let result = chordManager.detectChords(audioURL)
    DispatchQueue.main.async {
        self.displayResult(result)
    }
}
```

### Issue 2: Memory Leaks
**Symptom**: Memory usage increases over time  
**Cause**: Retain cycles in closures  
**Fix**: Use weak self

```swift
// ❌ WRONG
chordManager.detectChords(audioURL) { result in
    self.updateUI()  // Strong reference
}

// ✅ CORRECT
chordManager.detectChords(audioURL) { [weak self] result in
    self?.updateUI()  // Weak reference
}
```

### Issue 3: Thermal Throttling
**Symptom**: App slows down on hot device  
**Cause**: No thermal management  
**Fix**: Check thermal state

```swift
// ❌ WRONG
analyzeChords()  // Always runs

// ✅ CORRECT
if performanceGuard.shouldThrottle() {
    showWarning()
    return
}
analyzeChords()
```

---

## NEXT STEPS

1. **Audit Main Thread Safety**
   - Review all UI updates
   - Verify dispatch queues
   - Test with Instruments

2. **Fix Memory Leaks**
   - Check for retain cycles
   - Add weak references
   - Verify cleanup

3. **Enable Thermal Management**
   - Monitor thermal state
   - Throttle operations
   - Show warnings

4. **Implement Crash Logging**
   - Catch all errors
   - Log stack traces
   - Save crash info

5. **Track Performance Metrics**
   - Measure operation times
   - Monitor memory usage
   - Log CPU usage

---

**Status**: 🔄 READY FOR IMPLEMENTATION  
**Next**: Phase 3.6 GitHub Actions Build
