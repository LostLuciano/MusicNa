# Phase 1 — Native Core Stabilization

**Status**: ✅ Implementation Complete  
**Date**: June 1, 2026  
**Target**: Stable, performant native iOS core without crashes or CPU overload

---

## 📋 Overview

Phase 1 focuses on creating a stable, performant native core that:

✅ **Imports audio files** from iPhone Files app securely  
✅ **Processes audio** without CPU maxing at 98%  
✅ **Prevents crashes** with proper resource management  
✅ **Uses precomputed demo data** to avoid redundant inference  
✅ **Tracks performance** with detailed logging and metrics  

---

## 🏗️ Architecture

### System Layer (`Runner/System/`)

#### 1. **Logger.swift**
Centralized logging system with performance tracking.

```swift
Logger.shared.info("Message")
Logger.shared.performance("Operation", duration: 1.5)
Logger.shared.error("Error message")
```

**Features**:
- Console + file logging
- Performance metrics
- Async file I/O (non-blocking)
- Log file access for debugging

#### 2. **ProcessingGate.swift**
Ensures only one heavy operation runs at a time.

```swift
// Request operation
let canStart = processingGate.requestOperation(.separation)

// Complete operation
processingGate.completeOperation(.separation)

// Check status
let isActive = processingGate.isOperationActive(.separation)
```

**Operations** (by priority):
1. Separation (100)
2. Recording (90)
3. Export (80)
4. Chord Detection (50)
5. Beat Detection (50)
6. Analysis (40)

**Behavior**:
- Only one operation active at a time
- Others queued by priority
- Prevents CPU overload
- Async wait support

#### 3. **PerformanceGuard.swift**
Monitors thermal state, memory, and processing times.

```swift
// Start tracking
performanceGuard.startOperation("Stem Separation")
performanceGuard.addCheckpoint("Stem Separation", checkpoint: "STFT computed")
performanceGuard.endOperation("Stem Separation")

// Check throttling
if performanceGuard.shouldThrottle() {
    // Reduce processing intensity
}

// Get metrics
let memory = performanceGuard.getCurrentMemoryUsage()
let thermal = performanceGuard.getThermalState()
```

**Monitoring**:
- Thermal state (nominal → fair → serious → critical)
- Memory usage (current + peak)
- Processing time per operation
- Checkpoints for detailed timing

**Thresholds**:
- Memory warning: 800 MB
- Thermal throttle: serious or critical state
- Max processing time: 10 minutes

#### 4. **CacheManager.swift**
Handles temporary file storage and cleanup.

```swift
// Cache imported file
let cachedURL = try cacheManager.cacheImportedFile(sourceURL)

// Create temp file
let tempURL = cacheManager.createTempFile(withExtension: "m4a")

// Track output
cacheManager.trackOutputFile(outputURL)

// Get statistics
let stats = cacheManager.getCacheStatistics()
```

**Directories**:
- `Documents/Cache/Imports/` — Imported audio files
- `Documents/Cache/Output/` — Processed stems
- `NSTemporaryDirectory/NativeMusicX/` — Temporary files

**Cleanup**:
- Max cache size: 2 GB
- File expiration: 7 days
- Temp files: 1 hour
- LRU eviction when over limit

#### 5. **FileImportManager.swift**
Secure audio/video file imports from iPhone Files app.

```swift
// Present file picker
fileImportManager.presentFilePicker(from: viewController) { result in
    switch result {
    case .success(let url):
        // File imported and cached
    case .failure(let error):
        // Handle error
    }
}

// Check support
let supported = fileImportManager.isFileSupported(url)

// Get info
let info = try fileImportManager.getFileInfo(url)
```

**Supported Formats**:
- Audio: MP3, WAV, M4A, AAC, AIFF, FLAC, CAF
- Video: MP4, MOV (audio extracted)

**Security**:
- Security-scoped resource access
- Automatic cleanup
- Format validation
- File size tracking

---

### Data Layer (`Runner/Data/`)

#### 1. **StemProject.swift**
Complete music project with stems and metadata.

```swift
var project = StemProject(name: "My Song")
project.stemVolumes["vocals"] = 0.8
project.bpm = 120
project.chordData = ChordAnalysis(...)
```

**Properties**:
- Project ID, name, timestamps
- Original audio + stem URLs
- Analysis results (chords, beats)
- Mixer state (volumes, mutes, solo)
- Metadata (duration, BPM, genre, notes)

**Persistence**:
- JSON encoding/decoding
- URL path serialization
- Date ISO8601 format

#### 2. **TrackMetadata.swift**
Information about audio tracks (demo or imported).

```swift
let track = TrackMetadata(
    name: "Classical Symphony",
    artist: "Demo",
    genre: "Classical",
    duration: 150,
    isDemo: true
)

// Demo library
let demoTracks = DemoTrackLibrary.tracks
let track = DemoTrackLibrary.getTrack(byName: "Trap Beats")
```

**Demo Tracks** (11 bundled):
- Classical Symphony
- Trap Beats
- EDM Dance
- Dubstep Wobble
- Country Road
- Drum & Bass
- Folk Rock
- Latino Vibes
- Heavy Metal
- Reggaeton Dance
- RnB Soul

#### 3. **ProjectStore.swift**
Local persistence of StemProject data.

```swift
// Save project
try projectStore.saveProject(project)

// Load project
let project = try projectStore.loadProject(withId: id)

// Load all
let projects = try projectStore.loadAllProjects()

// Delete
try projectStore.deleteProject(withId: id)

// Statistics
let totalSize = try projectStore.getTotalStorageUsed()
```

**Storage**:
- `Documents/Projects/` — Project JSON files
- One file per project: `{id}.json`
- Sorted by update time

---

### AI Layer (`Runner/AI/`)

#### 1. **ModelManager.swift**
CoreML model loading and lifecycle.

```swift
// Load model
let model = try modelManager.loadModel(
    named: "dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1",
    computeUnits: .all
)

// Get available models
let models = modelManager.getAvailableModels()

// Unload
modelManager.unloadModel(named: "Chordcrnn")
```

**Compute Units**:
- `.all` — Neural Engine + GPU + CPU (default)
- `.cpuAndGPU` — GPU + CPU
- `.cpuOnly` — CPU only (debug/fallback)

**Models**:
- Stem Separation: DUN (FP32 or FP16)
- Chord Detection: Chordcrnn
- Beat Detection: ConvTCN

#### 2. **CoreMLStemSeparatorWrapper.swift**
Wraps CoreMLStemSeparator with ProcessingGate control.

```swift
// Separate with gate control
let stems = try await separatorWrapper.separate(
    audioURL: audioURL,
    processingMode: "Neural Engine",
    modelQuality: "Model Ringan",
    onProgress: { message, progress in
        print("\(message): \(Int(progress * 100))%")
    }
)

// Check status
let inProgress = separatorWrapper.isSeparationInProgress()
```

**Features**:
- ProcessingGate integration
- Performance tracking
- Thermal throttling detection
- Output file tracking
- Error handling

#### 3. **DemoDataManager.swift**
Instant access to precomputed demo stems and analysis.

```swift
// Get demo stems (instant, no inference)
let stems = try demoManager.getDemoStems(for: "Trap Beats")

// Get analysis data
let analysis = try demoManager.getDemoAnalysisData(for: "Trap Beats")

// Check availability
let hasStemsAvailable = demoManager.hasDemoStems(for: "Trap Beats")
let hasAnalysisAvailable = demoManager.hasAnalysisData(for: "Trap Beats")

// List all demo tracks
let demoTracks = demoManager.getAvailableDemoTracks()
```

**Demo Data**:
- Precomputed stems for all 11 demo tracks
- Analysis data (BPM, chords, beats)
- Instant loading (no inference)
- Reduces CPU load significantly

---

## 🎯 Key Features

### 1. File Import
✅ UIDocumentPickerViewController with security-scoped access  
✅ Format validation (MP3, WAV, M4A, AAC, AIFF, FLAC, MP4, MOV)  
✅ Automatic caching to Documents/Cache/Imports/  
✅ File size and duration tracking  

### 2. Processing Gate
✅ Only one heavy operation at a time  
✅ Priority-based queuing  
✅ Prevents CPU overload  
✅ Async wait support  

### 3. Performance Monitoring
✅ Thermal state tracking  
✅ Memory usage monitoring  
✅ Processing time checkpoints  
✅ Throttling decisions  

### 4. Cache Management
✅ Automatic cleanup (LRU eviction)  
✅ Size limits (2 GB max)  
✅ File expiration (7 days)  
✅ Category tracking (import/output/temp)  

### 5. Demo Data
✅ 11 precomputed demo tracks  
✅ Instant stem loading (no inference)  
✅ Precomputed analysis data  
✅ Reduces CPU load for demos  

### 6. Project Persistence
✅ Local JSON storage  
✅ Project metadata  
✅ Mixer state preservation  
✅ Analysis results caching  

---

## 📊 Performance Targets

### CPU Usage
- **Idle**: < 5%
- **Playback**: < 15%
- **Separation**: Controlled by ProcessingGate (one at a time)
- **Demo tracks**: < 5% (precomputed)

### Memory Usage
- **App base**: ~50 MB
- **Audio buffers**: ~100-200 MB
- **Models (loaded)**: ~300-500 MB
- **Peak**: ~500-700 MB
- **Warning threshold**: 800 MB

### Processing Time
- **Stem Separation (2:00 track)**: ~30-60s (ANE)
- **Chord Detection**: ~5-10s
- **Beat Detection**: ~3-5s
- **Demo stems**: < 1s (instant)

### Thermal Management
- **Nominal**: Full speed
- **Fair**: Monitor
- **Serious**: Throttle
- **Critical**: Pause operations

---

## 🔧 Usage Examples

### Import Audio File
```swift
let fileImporter = FileImportManager.shared

fileImporter.presentFilePicker(from: viewController) { result in
    switch result {
    case .success(let cachedURL):
        Logger.shared.info("File imported: \(cachedURL.lastPathComponent)")
        
        // Use cached URL for processing
        let stems = try await separatorWrapper.separate(
            audioURL: cachedURL,
            onProgress: { message, progress in
                print("\(message): \(Int(progress * 100))%")
            }
        )
        
    case .failure(let error):
        Logger.shared.error("Import failed: \(error.localizedDescription)")
    }
}
```

### Process Audio with Gate Control
```swift
let wrapper = CoreMLStemSeparatorWrapper.shared

do {
    let stems = try await wrapper.separate(
        audioURL: audioURL,
        processingMode: "Neural Engine",
        modelQuality: "Model Ringan",
        onProgress: { message, progress in
            DispatchQueue.main.async {
                self.progressLabel.text = message
                self.progressView.progress = Float(progress)
            }
        }
    )
    
    // Save project
    var project = StemProject(name: "My Song")
    project.stemURLs = stems
    try ProjectStore.shared.saveProject(project)
    
} catch {
    Logger.shared.error("Separation failed: \(error.localizedDescription)")
}
```

### Load Demo Track
```swift
let demoManager = DemoDataManager.shared

// Get precomputed stems (instant)
let stems = try demoManager.getDemoStems(for: "Trap Beats")

// Get analysis data
let analysis = try demoManager.getDemoAnalysisData(for: "Trap Beats")

// Load into audio engine
try audioEngine.loadStemFiles(stems)
```

### Monitor Performance
```swift
let guard = PerformanceGuard.shared

// Check thermal state
if guard.isThermalThrottling() {
    Logger.shared.warning("Device is hot!")
}

// Get memory usage
let memory = guard.getCurrentMemoryUsage()
print("Memory: \(memory / 1024 / 1024) MB")

// Get report
print(guard.getPerformanceReport())
```

---

## ✅ Verification Checklist

### Phase 1 Completion

- [x] **File Import**
  - [x] UIDocumentPickerViewController implemented
  - [x] Security-scoped resource access
  - [x] Format validation (MP3, WAV, M4A, AAC, AIFF, FLAC, MP4, MOV)
  - [x] Automatic caching to Documents/Cache/Imports/
  - [x] File size and duration tracking

- [x] **Processing Gate**
  - [x] Only one heavy operation at a time
  - [x] Priority-based queuing
  - [x] Prevents CPU overload
  - [x] Async wait support

- [x] **Performance Guard**
  - [x] Thermal state monitoring
  - [x] Memory usage tracking
  - [x] Processing time checkpoints
  - [x] Throttling decisions

- [x] **Cache Manager**
  - [x] Automatic cleanup (LRU eviction)
  - [x] Size limits (2 GB max)
  - [x] File expiration (7 days)
  - [x] Category tracking

- [x] **Demo Data**
  - [x] 11 precomputed demo tracks
  - [x] Instant stem loading (no inference)
  - [x] Precomputed analysis data
  - [x] Reduces CPU load

- [x] **Project Persistence**
  - [x] Local JSON storage
  - [x] Project metadata
  - [x] Mixer state preservation
  - [x] Analysis results caching

- [x] **Logging**
  - [x] Centralized logging system
  - [x] Console + file output
  - [x] Performance metrics
  - [x] Async file I/O

---

## 📁 File Structure

```
Runner/
├── System/
│   ├── Logger.swift                    # Centralized logging
│   ├── ProcessingGate.swift            # Operation serialization
│   ├── PerformanceGuard.swift          # Performance monitoring
│   ├── CacheManager.swift              # File cache management
│   └── FileImportManager.swift         # Audio file imports
├── Data/
│   ├── StemProject.swift               # Project model
│   ├── TrackMetadata.swift             # Track information
│   └── ProjectStore.swift              # Project persistence
├── AI/
│   ├── ModelManager.swift              # CoreML model loading
│   ├── CoreMLStemSeparatorWrapper.swift # Wrapper with gate control
│   └── DemoDataManager.swift           # Precomputed demo data
├── AudioEngineManager.swift            # (existing)
├── CoreMLStemSeparator.swift           # (existing)
└── [other existing files]
```

---

## 🚀 Next Steps (Phase 2)

- [ ] Real-time stem separation (streaming)
- [ ] Pitch shifting per stem
- [ ] Time stretching without pitch change
- [ ] EQ per stem
- [ ] Reverb/delay effects
- [ ] Recording mixed output
- [ ] Waveform visualization
- [ ] Spectrum analyzer

---

## 📝 Notes

### CPU Management
- ProcessingGate ensures only one heavy operation at a time
- Demo tracks use precomputed stems (no inference)
- PerformanceGuard monitors thermal state and throttles if needed
- Async operations prevent main thread blocking

### Memory Management
- CacheManager limits total cache to 2 GB
- LRU eviction removes least-recently-used files
- Temp files cleaned up after 1 hour
- Models unloaded when not in use

### File Organization
- Imported files: `Documents/Cache/Imports/`
- Output stems: `Documents/Cache/Output/`
- Temp files: `NSTemporaryDirectory/NativeMusicX/`
- Projects: `Documents/Projects/`
- Logs: `Documents/NativeMusicX.log`

### Error Handling
- All operations wrapped in try-catch
- Detailed error messages logged
- Fallback to demo data if inference fails
- Graceful degradation on resource constraints

---

## 🔗 Related Documentation

- `PROJECT_FEATURES_SUMMARY.md` — Complete feature overview
- `ARCHITECTURE.md` — System architecture
- `AI_MODEL_REQUIREMENTS.md` — ML model specifications

---

**Status**: ✅ Phase 1 Complete  
**Last Updated**: June 1, 2026  
**Ready for**: Phase 2 Development

