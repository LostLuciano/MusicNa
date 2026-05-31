# Phase 1 Integration Guide

**Quick start for integrating Phase 1 components into existing ViewControllers**

---

## 🔌 Integration Points

### 1. AppDelegate Setup

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Phase 1 managers
        _ = Logger.shared
        _ = ProcessingGate.shared
        _ = PerformanceGuard.shared
        _ = CacheManager.shared
        _ = ProjectStore.shared
        _ = DemoDataManager.shared
        
        Logger.shared.info("✅ Phase 1 managers initialized")
        return true
    }
}
```

### 2. Dashboard ViewController

```swift
class DashboardViewController: UIViewController {
    
    let fileImporter = FileImportManager.shared
    let demoManager = DemoDataManager.shared
    let separatorWrapper = CoreMLStemSeparatorWrapper.shared
    let projectStore = ProjectStore.shared
    
    @IBAction func importAudioTapped(_ sender: UIButton) {
        fileImporter.presentFilePicker(from: self) { [weak self] result in
            switch result {
            case .success(let cachedURL):
                self?.handleImportedFile(cachedURL)
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
    
    private func handleImportedFile(_ url: URL) {
        Task {
            do {
                // Start separation with gate control
                let stems = try await separatorWrapper.separate(
                    audioURL: url,
                    processingMode: "Neural Engine",
                    modelQuality: "Model Ringan",
                    onProgress: { [weak self] message, progress in
                        DispatchQueue.main.async {
                            self?.updateProgress(message: message, progress: progress)
                        }
                    }
                )
                
                // Create and save project
                var project = StemProject(name: url.deletingPathExtension().lastPathComponent)
                project.originalAudioURL = url
                project.stemURLs = stems
                project.duration = try self?.getAudioDuration(url) ?? 0
                
                try projectStore.saveProject(project)
                
                // Load into mixer
                try self?.audioEngine.loadStemFiles(stems)
                
                DispatchQueue.main.async {
                    self?.showSuccess("Separation completed!")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.showError(error)
                }
            }
        }
    }
    
    @IBAction func loadDemoTapped(_ sender: UISegmentedControl) {
        let demoTracks = demoManager.getAvailableDemoTracks()
        let selectedTrack = demoTracks[sender.selectedSegmentIndex]
        
        Task {
            do {
                // Load precomputed stems (instant)
                let stems = try demoManager.getDemoStems(for: selectedTrack)
                
                // Load analysis data
                let analysis = try demoManager.getDemoAnalysisData(for: selectedTrack)
                
                // Create project
                var project = StemProject(name: selectedTrack)
                project.stemURLs = stems
                project.bpm = analysis.bpm ?? 0
                
                try projectStore.saveProject(project)
                
                // Load into mixer
                try audioEngine.loadStemFiles(stems)
                
                DispatchQueue.main.async {
                    self.showSuccess("Demo loaded: \(selectedTrack)")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.showError(error)
                }
            }
        }
    }
    
    private func updateProgress(message: String, progress: Double) {
        progressLabel.text = message
        progressView.progress = Float(progress)
    }
    
    private func getAudioDuration(_ url: URL) throws -> TimeInterval {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}
```

### 3. Mixer ViewController

```swift
class MixerViewController: UIViewController {
    
    let audioEngine = AudioEngineManager()
    let projectStore = ProjectStore.shared
    
    @IBOutlet weak var vocalsSlider: UISlider!
    @IBOutlet weak var drumsSlider: UISlider!
    @IBOutlet weak var bassSlider: UISlider!
    @IBOutlet weak var guitarSlider: UISlider!
    @IBOutlet weak var pianoSlider: UISlider!
    @IBOutlet weak var otherSlider: UISlider!
    
    var currentProject: StemProject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSliders()
    }
    
    private func setupSliders() {
        let sliders: [(UISlider, String)] = [
            (vocalsSlider, "vocals"),
            (drumsSlider, "drums"),
            (bassSlider, "bass"),
            (guitarSlider, "guitar"),
            (pianoSlider, "piano"),
            (otherSlider, "other")
        ]
        
        for (slider, stem) in sliders {
            slider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
            slider.tag = stem.hashValue
        }
    }
    
    @objc func volumeChanged(_ slider: UISlider) {
        let stemName = String(describing: slider.tag)
        audioEngine.setVolume(stem: stemName, volume: slider.value)
        
        // Update project
        if var project = currentProject {
            project.stemVolumes[stemName] = slider.value
            try? projectStore.saveProject(project)
        }
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        do {
            try audioEngine.play()
        } catch {
            Logger.shared.error("Play failed: \(error.localizedDescription)")
        }
    }
    
    @IBAction func pauseTapped(_ sender: UIButton) {
        audioEngine.pause()
    }
    
    @IBAction func stopTapped(_ sender: UIButton) {
        audioEngine.stop()
    }
    
    @IBAction func exportTapped(_ sender: UIButton) {
        Task {
            do {
                let outputURL = CacheManager.shared.createTempFile(withExtension: "m4a")
                
                let volumes = [
                    "vocals": vocalsSlider.value,
                    "drums": drumsSlider.value,
                    "bass": bassSlider.value,
                    "guitar": guitarSlider.value,
                    "piano": pianoSlider.value,
                    "other": otherSlider.value
                ]
                
                try await audioEngine.exportStemMix(volumes: volumes, outputURL: outputURL)
                
                DispatchQueue.main.async {
                    self.showSuccess("Exported to: \(outputURL.lastPathComponent)")
                }
                
            } catch {
                DispatchQueue.main.async {
                    Logger.shared.error("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
```

### 4. Analytics ViewController

```swift
class AnalyticsViewController: UIViewController {
    
    let demoManager = DemoDataManager.shared
    let performanceGuard = PerformanceGuard.shared
    
    @IBOutlet weak var performanceLabel: UILabel!
    @IBOutlet weak var cacheLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateMetrics()
        
        // Update every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    private func updateMetrics() {
        // Performance metrics
        let report = performanceGuard.getPerformanceReport()
        performanceLabel.text = report
        
        // Cache statistics
        let stats = CacheManager.shared.getCacheStatistics()
        let cacheReport = CacheManager.shared.getCacheReport()
        cacheLabel.text = cacheReport
    }
}
```

### 5. Settings ViewController

```swift
class SettingsViewController: UIViewController {
    
    @IBAction func clearCacheTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Clear Cache?", message: "This will remove temporary files.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            CacheManager.shared.clearTempFiles()
            Logger.shared.info("Cache cleared")
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func clearProjectsTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete All Projects?", message: "This cannot be undone.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            try? ProjectStore.shared.clearAllProjects()
            Logger.shared.info("All projects deleted")
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func viewLogsTapped(_ sender: UIButton) {
        let logURL = Logger.shared.getLogFileURL()
        let activityVC = UIActivityViewController(activityItems: [logURL], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
```

---

## 🔄 Data Flow

### Import → Process → Save → Play

```
1. User taps "Import Audio"
   ↓
2. FileImportManager presents UIDocumentPickerViewController
   ↓
3. User selects file
   ↓
4. FileImportManager validates format & caches file
   ↓
5. DashboardViewController calls CoreMLStemSeparatorWrapper.separate()
   ↓
6. ProcessingGate serializes operation
   ↓
7. PerformanceGuard tracks metrics
   ↓
8. CoreMLStemSeparator runs inference
   ↓
9. Output stems saved to Documents/Cache/Output/
   ↓
10. StemProject created and saved to Documents/Projects/
    ↓
11. AudioEngineManager loads stems
    ↓
12. MixerViewController displays controls
    ↓
13. User adjusts volumes and plays
```

---

## 📊 Monitoring

### Check Processing Status

```swift
let gate = ProcessingGate.shared
let (active, queued) = gate.getQueueStatus()

if let active = active {
    print("Active: \(active.description)")
}

for operation in queued {
    print("Queued: \(operation.description)")
}
```

### Monitor Performance

```swift
let guard = PerformanceGuard.shared

// Thermal state
let thermal = guard.getThermalState()
if guard.isThermalThrottling() {
    print("⚠️ Device is hot!")
}

// Memory
let memory = guard.getCurrentMemoryUsage()
print("Memory: \(memory / 1024 / 1024) MB")

// Operations
let operations = guard.getAllOperations()
for (name, metric) in operations {
    print("\(name): \(metric.elapsedTime)s")
}
```

### View Cache Statistics

```swift
let cache = CacheManager.shared
let stats = cache.getCacheStatistics()

print("Total: \(stats.totalSize / 1024 / 1024) MB")
print("Files: \(stats.fileCount)")

for (category, info) in stats.byCategory {
    print("\(category): \(info.count) files (\(info.size / 1024 / 1024) MB)")
}
```

---

## ⚠️ Error Handling

### Common Errors

```swift
// File not found
if error.code == 404 {
    print("File not found")
}

// Format not supported
if error.code == 400 {
    print("Format not supported")
}

// Processing timeout
if error.code == 503 {
    print("Processing queue timeout")
}

// Thermal throttling
if performanceGuard.isThermalThrottling() {
    print("Device is thermally throttled")
}
```

---

## 🧪 Testing

### Test File Import

```swift
// Test with demo file
let demoURL = Bundle.main.url(forResource: "classical", withExtension: "caf")!
let cachedURL = try CacheManager.shared.cacheImportedFile(demoURL)
print("✅ Cached: \(cachedURL.lastPathComponent)")
```

### Test Processing Gate

```swift
let gate = ProcessingGate.shared

// Request operation
let canStart = gate.requestOperation(.separation)
print("Can start: \(canStart)")

// Complete operation
gate.completeOperation(.separation)
```

### Test Demo Data

```swift
let demoManager = DemoDataManager.shared

// Get demo stems
let stems = try demoManager.getDemoStems(for: "Trap Beats")
print("✅ Loaded \(stems.count) stems")

// Get analysis
let analysis = try demoManager.getDemoAnalysisData(for: "Trap Beats")
print("✅ BPM: \(analysis.bpm ?? 0)")
```

---

## 📝 Logging

### View Logs

```swift
// Get log file
let logURL = Logger.shared.getLogFileURL()

// Share logs
let activityVC = UIActivityViewController(activityItems: [logURL], applicationActivities: nil)
present(activityVC, animated: true)

// Clear logs
Logger.shared.clearLogs()
```

### Log Levels

```swift
Logger.shared.debug("Debug message")
Logger.shared.info("Info message")
Logger.shared.warning("Warning message")
Logger.shared.error("Error message")
Logger.shared.performance("Operation", duration: 1.5)
```

---

## ✅ Integration Checklist

- [ ] Initialize managers in AppDelegate
- [ ] Add file import button to Dashboard
- [ ] Add demo track selector to Dashboard
- [ ] Connect volume sliders in Mixer
- [ ] Add export button to Mixer
- [ ] Display metrics in Analytics
- [ ] Add cache/project management to Settings
- [ ] Test file import
- [ ] Test demo track loading
- [ ] Test stem separation
- [ ] Test mixer controls
- [ ] Test export
- [ ] Monitor logs
- [ ] Check performance metrics

---

## 🚀 Ready for Phase 2

Once Phase 1 integration is complete:

1. ✅ File import working
2. ✅ Demo tracks loading instantly
3. ✅ Stem separation with gate control
4. ✅ Mixer controls functional
5. ✅ Projects persisting locally
6. ✅ Performance monitoring active
7. ✅ Logs available for debugging

**Next**: Phase 2 — Enhanced Features (pitch shifting, time stretching, EQ, effects)

