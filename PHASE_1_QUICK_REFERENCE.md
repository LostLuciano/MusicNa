# Phase 1 — Quick Reference Card

**One-page guide to Phase 1 components and usage**

---

## 🔧 Core Components

### Logger
```swift
Logger.shared.info("Message")
Logger.shared.error("Error")
Logger.shared.performance("Op", duration: 1.5)
Logger.shared.getLogFileURL()
```

### ProcessingGate
```swift
processingGate.requestOperation(.separation)
processingGate.completeOperation(.separation)
processingGate.isOperationActive(.separation)
processingGate.getQueueStatus()
```

### PerformanceGuard
```swift
performanceGuard.startOperation("Op")
performanceGuard.addCheckpoint("Op", checkpoint: "Step")
performanceGuard.endOperation("Op")
performanceGuard.isThermalThrottling()
performanceGuard.getCurrentMemoryUsage()
```

### CacheManager
```swift
cacheManager.cacheImportedFile(url)
cacheManager.createTempFile(withExtension: "m4a")
cacheManager.trackOutputFile(url)
cacheManager.getCacheStatistics()
cacheManager.clearTempFiles()
```

### FileImportManager
```swift
fileImporter.presentFilePicker(from: vc) { result in
    // Handle result
}
fileImporter.isFileSupported(url)
```

### ProjectStore
```swift
try projectStore.saveProject(project)
let project = try projectStore.loadProject(withId: id)
let projects = try projectStore.loadAllProjects()
try projectStore.deleteProject(withId: id)
```

### DemoDataManager
```swift
let stems = try demoManager.getDemoStems(for: "Trap Beats")
let analysis = try demoManager.getDemoAnalysisData(for: "Trap Beats")
let tracks = demoManager.getAvailableDemoTracks()
```

### CoreMLStemSeparatorWrapper
```swift
let stems = try await separatorWrapper.separate(
    audioURL: url,
    processingMode: "Neural Engine",
    modelQuality: "Model Ringan",
    onProgress: { msg, progress in }
)
```

---

## 📁 Directories

| Directory | Purpose |
|-----------|---------|
| `Documents/Cache/Imports/` | Imported audio files |
| `Documents/Cache/Output/` | Processed stems |
| `NSTemporaryDirectory/NativeMusicX/` | Temporary files |
| `Documents/Projects/` | Project JSON files |
| `Documents/NativeMusicX.log` | Log file |

---

## 🎯 Common Tasks

### Import Audio
```swift
fileImporter.presentFilePicker(from: self) { result in
    if case .success(let url) = result {
        // url is cached and ready to use
    }
}
```

### Load Demo Track
```swift
let stems = try demoManager.getDemoStems(for: "Trap Beats")
try audioEngine.loadStemFiles(stems)
```

### Separate Audio
```swift
let stems = try await separatorWrapper.separate(
    audioURL: cachedURL,
    onProgress: { msg, progress in
        print("\(msg): \(Int(progress * 100))%")
    }
)
```

### Save Project
```swift
var project = StemProject(name: "My Song")
project.stemURLs = stems
try projectStore.saveProject(project)
```

### Monitor Performance
```swift
if performanceGuard.isThermalThrottling() {
    print("Device is hot!")
}
let memory = performanceGuard.getCurrentMemoryUsage()
```

### Check Processing Queue
```swift
let (active, queued) = processingGate.getQueueStatus()
if let active = active {
    print("Active: \(active.description)")
}
```

---

## ⚠️ Error Codes

| Code | Meaning |
|------|---------|
| 100 | User cancelled |
| 400 | Invalid format / Bad request |
| 404 | File/project not found |
| 500 | Processing error |
| 503 | Queue timeout |

---

## 🎵 Demo Tracks

1. Classical Symphony
2. Trap Beats
3. EDM Dance
4. Dubstep Wobble
5. Country Road
6. Drum & Bass
7. Folk Rock
8. Latino Vibes
9. Heavy Metal
10. Reggaeton Dance
11. RnB Soul

---

## 📊 Performance Targets

| Metric | Target |
|--------|--------|
| CPU (idle) | < 5% |
| CPU (playback) | < 15% |
| CPU (demo) | < 5% |
| Memory (peak) | ~700 MB |
| Demo load | < 1s |
| Separation (2:00) | ~30-60s |

---

## 🔄 Data Flow

```
Import → Cache → Separate → Save → Load → Play
```

---

## 📝 Logging Levels

```swift
Logger.shared.debug("Debug")      // Detailed info
Logger.shared.info("Info")        // General info
Logger.shared.warning("Warning")  // Warnings
Logger.shared.error("Error")      // Errors
Logger.shared.performance("Op", duration: 1.5)  // Metrics
```

---

## 🧪 Quick Test

```swift
// Test import
let demoURL = Bundle.main.url(forResource: "classical", withExtension: "caf")!
let cached = try CacheManager.shared.cacheImportedFile(demoURL)
print("✅ Cached: \(cached.lastPathComponent)")

// Test demo
let stems = try DemoDataManager.shared.getDemoStems(for: "Trap Beats")
print("✅ Loaded \(stems.count) stems")

// Test gate
let gate = ProcessingGate.shared
let canStart = gate.requestOperation(.separation)
print("✅ Can start: \(canStart)")
gate.completeOperation(.separation)

// Test performance
let guard = PerformanceGuard.shared
let memory = guard.getCurrentMemoryUsage()
print("✅ Memory: \(memory / 1024 / 1024) MB")
```

---

## 🚀 Integration Checklist

- [ ] Initialize managers in AppDelegate
- [ ] Add import button to Dashboard
- [ ] Add demo selector to Dashboard
- [ ] Connect volume sliders in Mixer
- [ ] Add export button to Mixer
- [ ] Display metrics in Analytics
- [ ] Test file import
- [ ] Test demo loading
- [ ] Test separation
- [ ] Test mixer
- [ ] Test export
- [ ] Monitor logs

---

## 📞 Help

| Issue | Solution |
|-------|----------|
| CPU high | Check `ProcessingGate.getQueueStatus()` |
| Memory high | Check `PerformanceGuard.getCurrentMemoryUsage()` |
| Device hot | Check `PerformanceGuard.getThermalState()` |
| File not found | Check `CacheManager.getCacheStatistics()` |
| Import failed | Check `FileImportManager.isFileSupported()` |
| Separation slow | Check `PerformanceGuard.isThermalThrottling()` |

---

## 📚 Documentation

- **PHASE_1_IMPLEMENTATION.md** — Full technical docs
- **PHASE_1_INTEGRATION_GUIDE.md** — Integration examples
- **PHASE_1_SUMMARY.md** — Overview and goals
- **PHASE_1_QUICK_REFERENCE.md** — This file

---

## ✅ Phase 1 Status

✅ File import working  
✅ Demo tracks instant  
✅ Stem separation with gate  
✅ Project persistence  
✅ Performance monitoring  
✅ Logging active  
✅ Ready for Phase 2  

---

**Last Updated**: June 1, 2026  
**Status**: ✅ Complete

