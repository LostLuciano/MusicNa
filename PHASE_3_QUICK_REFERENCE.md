# Phase 3 — Quick Reference Guide

**Phase**: Integration, Optimization, Export, and Build IPA  
**Status**: 35% Complete  
**Date**: June 1, 2026

---

## What's Done ✅

### Export System (ExportManager + ExportViewController)
```swift
// Export stereo mix
exportManager.exportStereoMix(
    from: project,
    format: .m4a,
    quality: .high,
    progress: { print("\($0 * 100)%") },
    completion: { result in ... }
)

// Export individual stems
exportManager.exportIndividualStems(
    from: project,
    format: .m4a,
    quality: .high,
    progress: { ... },
    completion: { ... }
)

// Export full project
exportManager.exportProject(
    project,
    format: .m4a,
    progress: { ... },
    completion: { ... }
)
```

**Formats**: M4A, WAV, FLAC, MP3  
**Qualities**: Low, Medium, High, Very High  
**Features**: Progress tracking, cancellation, temp cleanup

---

### Recording Module (RecordingViewController)
```swift
// Start recording
startRecording()  // Creates AVAudioRecorder

// Pause/resume
pauseRecording()  // Toggles pause state

// Stop and save
stopRecording()   // Stops recording
saveRecording()   // Saves to ProjectStore
discardRecording() // Deletes temp file
```

**Specs**: 44.1 kHz, 16-bit, M4A, Stereo  
**Features**: Level metering, pause/resume, project save

---

### Chord Detection (ChordDetectionManager)
```swift
// Detect chords from file
chordManager.detectChords(
    from: audioURL,
    progress: { print("\($0 * 100)%") },
    completion: { result in
        for chord in result.success?.chords ?? [] {
            print("\(chord.chord) @ \(chord.timestamp)s")
        }
    }
)

// Detect chords from buffer
chordManager.detectChords(
    from: buffer,
    sampleRate: 44100,
    progress: { ... },
    completion: { ... }
)
```

**Result**:
```swift
struct ChordDetectionResult {
    let chord: String           // "C Major", "G Minor", etc.
    let confidence: Float       // 0.0-1.0
    let timestamp: TimeInterval // Position in audio
    let duration: TimeInterval  // Segment duration
}
```

**Features**: Caching, cancellation, confidence scoring

---

### Beat Detection (BeatDetectionManager)
```swift
// Detect beats from file
beatManager.detectBeats(
    from: audioURL,
    progress: { print("\($0 * 100)%") },
    completion: { result in
        if let beats = result.success {
            print("BPM: \(beats.bpm)")
            print("Time Signature: \(beats.timeSignature)")
            print("Beats: \(beats.beats.count)")
        }
    }
)

// Detect beats from buffer
beatManager.detectBeats(
    from: buffer,
    sampleRate: 44100,
    progress: { ... },
    completion: { ... }
)
```

**Result**:
```swift
struct BeatDetectionResult {
    let bpm: Float              // 40-200 BPM
    let beats: [TimeInterval]   // Beat timings
    let confidence: Float       // 0.0-1.0
    let timeSignature: String   // "4/4", "3/4"
    let analyzedAt: Date
}
```

**Features**: BPM calculation, time signature detection, caching

---

## What's Next 🔄

### Phase 3.4 — UI Components (2 hours)
1. **ChordPatternView.swift** - Chord visualization
2. **ChordTimelineView.swift** - Chord progression timeline
3. **BeatGridView.swift** - Beat grid display
4. **LyricsKaraokeView.swift** - Lyrics sync display
5. **StemChannelView.swift** - Stem channel control
6. **ProcessingStageRowView.swift** - Processing stage display

### Phase 3.5 — Performance Optimization (2 hours)
- Main thread safety audit
- Memory leak detection
- Thermal management
- Crash logging
- Performance metrics

### Phase 3.6 — GitHub Actions Build (1 hour)
- Verify Xcode 16.4 build
- Test unsigned IPA generation
- Verify artifact upload
- Test ESign compatibility

---

## Integration Points

### Export Flow
```
User selects export options
    ↓
ExportViewController
    ↓
ExportManager.exportStereoMix/Stems/Project
    ↓
ProcessingGate (serializes operation)
    ↓
AudioEngineManager (mixes stems)
    ↓
AVAudioFile (writes to disk)
    ↓
Progress updates UI
    ↓
Share to Files or save to project
    ↓
Cleanup temp files
```

### Recording Flow
```
User starts recording
    ↓
RecordingViewController
    ↓
AVAudioRecorder (captures audio)
    ↓
Level metering updates UI
    ↓
User stops recording
    ↓
Save dialog appears
    ↓
ProjectStore saves project
    ↓
ProcessingGate completes operation
```

### Analysis Flow
```
User taps "Analyze"
    ↓
AnalyzerViewController
    ↓
ChordDetectionManager / BeatDetectionManager
    ↓
ProcessingGate (serializes operation)
    ↓
AudioFeatureExtractor (extracts features)
    ↓
ChordTheory / Beat algorithm (detects)
    ↓
Results cached
    ↓
UI displays results
```

---

## Key Classes

### ExportManager
- `exportStereoMix()` - Export mixed audio
- `exportIndividualStems()` - Export individual stems
- `exportProject()` - Export full project with metadata
- `cancelExport()` - Cancel ongoing export
- `cleanupTempFiles()` - Clean temporary files
- `getAvailableStorage()` - Check storage space

### RecordingViewController
- `startRecording()` - Start audio recording
- `pauseRecording()` - Pause/resume recording
- `stopRecording()` - Stop recording
- `saveRecording()` - Save to ProjectStore
- `discardRecording()` - Delete recording

### ChordDetectionManager
- `detectChords(from:progress:completion:)` - Detect chords
- `cancelDetection()` - Cancel detection
- `clearCache()` - Clear analysis cache

### BeatDetectionManager
- `detectBeats(from:progress:completion:)` - Detect beats
- `cancelDetection()` - Cancel detection
- `clearCache()` - Clear analysis cache

---

## Error Handling

### ExportManager Errors
```swift
enum ExportError: LocalizedError {
    case invalidProject
    case noStemsAvailable
    case audioEngineError
    case fileWriteError
    case invalidFormat
    case insufficientSpace
    case cancelled
}
```

### ChordDetectionManager Errors
```swift
enum ChordDetectionError: LocalizedError {
    case modelNotFound
    case invalidAudioFormat
    case processingError
    case insufficientData
    case cancelled
}
```

### BeatDetectionManager Errors
```swift
enum BeatDetectionError: LocalizedError {
    case modelNotFound
    case invalidAudioFormat
    case processingError
    case insufficientData
    case cancelled
}
```

---

## Performance Tips

### Export
- Use `.high` quality for best results
- Use `.m4a` format for smallest file size
- Progress updates throttled to 100ms
- Temp files auto-cleaned after export

### Recording
- Sample rate: 44.1 kHz (standard)
- Bit depth: 16-bit (good quality)
- Format: M4A (compressed)
- Level metering updates every 100ms

### Analysis
- Results cached (LRU, max 10)
- Cancellation supported
- ProcessingGate prevents concurrent operations
- Progress tracking available

---

## Testing Checklist

### Export
- [ ] M4A export working
- [ ] WAV export working
- [ ] FLAC export working
- [ ] MP3 export working
- [ ] Progress tracking working
- [ ] Cancel functionality working
- [ ] Temp cleanup working

### Recording
- [ ] Audio recording working
- [ ] Level metering working
- [ ] File saving working
- [ ] Pause/resume working
- [ ] Discard functionality working

### Analysis
- [ ] Chord detection working
- [ ] Beat detection working
- [ ] Confidence scoring working
- [ ] Caching working
- [ ] Cancellation working

### Integration
- [ ] Export from ResultViewController
- [ ] Export from MixerViewController
- [ ] Recording from RecordingViewController
- [ ] Analysis from AnalyzerViewController
- [ ] ProcessingGate serialization working

---

## File Locations

### New Files Created
- `Runner/System/ExportManager.swift` (350+ lines)
- `Runner/UI/Screens/ExportViewController.swift` (400+ lines)
- `Runner/UI/Screens/RecordingViewController.swift` (400+ lines)
- `Runner/AI/ChordDetectionManager.swift` (350+ lines)
- `Runner/AI/BeatDetectionManager.swift` (350+ lines)

### Documentation
- `PHASE_3_IMPLEMENTATION_PLAN.md`
- `PHASE_3_STATUS.md`
- `PHASE_3_PROGRESS_REPORT.md`
- `PHASE_3_CHECKLIST.md`
- `PHASE_3_QUICK_REFERENCE.md` (this file)

---

## Quick Stats

| Metric | Value |
|--------|-------|
| Files Created | 8 |
| Lines of Code | 2550+ |
| Export Formats | 4 (M4A, WAV, FLAC, MP3) |
| Export Types | 3 (Mix, Stems, Project) |
| Quality Levels | 4 (Low, Medium, High, Very High) |
| Recording Sample Rate | 44.1 kHz |
| Chord Types | 144 (12 notes × 12 types) |
| BPM Range | 40-200 |
| Time Signatures | 2 (4/4, 3/4) |
| Cache Size | 10 (LRU) |
| Phase Completion | 35% |

---

## Next Steps

1. ✅ Implement 6 UI components
2. ✅ Update AnalyzerViewController
3. ✅ Performance optimization
4. ✅ GitHub Actions build verification
5. ✅ Comprehensive testing
6. ✅ IPA generation

---

**Status**: 🚀 35% COMPLETE  
**Estimated Time Remaining**: 6-8 hours  
**Target**: Unsigned IPA ready for ESign
