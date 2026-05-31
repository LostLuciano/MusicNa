# Phase 3 — Next Steps (Session 3)

**Current Status**: 60% Complete  
**Remaining**: 40% (Performance Optimization + Build + Integration)  
**Estimated Time**: 4 hours

---

## IMMEDIATE PRIORITIES

### Priority 1: AnalyzerViewController Integration (1 hour)
**File**: `Runner/UI/Screens/AnalyzerViewController.swift`

**Tasks**:
- [ ] Add "Analyze Chords" button
- [ ] Add "Analyze Beats" button
- [ ] Add "Sync Lyrics" button
- [ ] Integrate ChordDetectionManager
- [ ] Integrate BeatDetectionManager
- [ ] Display ChordPatternView
- [ ] Display ChordTimelineView
- [ ] Display BeatGridView
- [ ] Display LyricsKaraokeView
- [ ] Handle analysis results
- [ ] Show progress display
- [ ] Connect to playback sync

**Code Template**:
```swift
// Chord analysis
@objc private func analyzeChords() {
    guard let project = project else { return }
    
    let chordManager = ChordDetectionManager.shared
    chordManager.detectChords(from: project.originalAudioURL!) { result in
        switch result {
        case .success(let chords):
            self.chordPatternView.updateChord(...)
            self.chordTimelineView.loadChords(...)
        case .failure(let error):
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
}

// Beat analysis
@objc private func analyzeBeats() {
    guard let project = project else { return }
    
    let beatManager = BeatDetectionManager.shared
    beatManager.detectBeats(from: project.originalAudioURL!) { result in
        switch result {
        case .success(let beats):
            self.beatGridView.updateBeats(
                bpm: beats.bpm,
                timeSignature: beats.timeSignature,
                beats: beats.beats,
                confidence: beats.confidence
            )
        case .failure(let error):
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
}
```

---

### Priority 2: Performance Optimization (2 hours)
**Files to Update**:
- `Runner/System/PerformanceGuard.swift`
- `Runner/System/ProcessingGate.swift`
- `Runner/AI/ChordDetectionManager.swift`
- `Runner/AI/BeatDetectionManager.swift`
- `Runner/UI/Screens/AnalyzerViewController.swift`

**Tasks**:
- [ ] Main thread safety audit
  - Verify all UI updates on main thread
  - Check for blocking operations
  - Profile with Instruments

- [ ] Memory leak detection
  - Check for retain cycles
  - Verify cleanup after processing
  - Test with Instruments Memory Profiler

- [ ] Thermal management
  - Monitor thermal state
  - Throttle operations on high temp
  - Display thermal warning

- [ ] Crash logging
  - Implement crash handler
  - Capture stack traces
  - Preserve error context

- [ ] Performance metrics
  - Measure export time
  - Measure analysis time
  - Measure memory usage
  - Measure CPU usage

---

### Priority 3: GitHub Actions Build (1 hour)
**File**: `.github/workflows/build-ios-ipa.yml`

**Tasks**:
- [ ] Verify Xcode 16.4 selection
- [ ] Verify iOS deployment target
- [ ] Verify CODE_SIGNING_ALLOWED=NO
- [ ] Test archive generation
- [ ] Test IPA packaging
- [ ] Verify artifact upload
- [ ] Test ESign compatibility

**Checklist**:
```yaml
- Xcode version: 16.4+
- iOS target: 15.0+
- Signing: Disabled (unsigned)
- Architecture: arm64
- Output: Payload/*.app → IPA
```

---

### Priority 4: Final Integration Testing (1 hour)
**Test Cases**:

#### Export Flow
- [ ] Import audio file
- [ ] Run separation
- [ ] Export stereo mix (M4A)
- [ ] Export individual stems
- [ ] Export full project
- [ ] Verify files created
- [ ] Verify quality settings

#### Recording Flow
- [ ] Start recording
- [ ] Check level metering
- [ ] Pause/resume recording
- [ ] Stop recording
- [ ] Save to ProjectStore
- [ ] Verify file saved

#### Analysis Flow
- [ ] Load audio file
- [ ] Analyze chords
- [ ] Display chord results
- [ ] Analyze beats
- [ ] Display beat results
- [ ] Sync with playback

#### UI Components
- [ ] ChordPatternView displays correctly
- [ ] ChordTimelineView scrolls
- [ ] BeatGridView updates
- [ ] LyricsKaraokeView syncs
- [ ] StemChannelView controls work
- [ ] ProcessingStageRowView animates

---

## DETAILED TASKS

### Task 1: Update AnalyzerViewController

**Current State**: Placeholder with tabs  
**Required Changes**:
1. Add analysis buttons to header
2. Create tab views for each analysis type
3. Integrate ChordDetectionManager
4. Integrate BeatDetectionManager
5. Display UI components
6. Handle results
7. Sync with playback

**Estimated**: 1 hour

---

### Task 2: Performance Optimization

**Main Thread Safety**:
```swift
// ✅ CORRECT
DispatchQueue.main.async {
    self.updateUI()
}

// ❌ WRONG
self.updateUI()  // On background thread
```

**Memory Management**:
```swift
// ✅ CORRECT
defer { processingGate.completeOperation(.analysis) }

// ❌ WRONG
// Forgot to complete operation
```

**Thermal Management**:
```swift
// ✅ CORRECT
if performanceGuard.thermalState == .critical {
    throttleOperations()
}

// ❌ WRONG
// Ignored thermal state
```

**Estimated**: 2 hours

---

### Task 3: GitHub Actions Build

**Current Workflow**: `.github/workflows/build-ios-ipa.yml`

**Verification Steps**:
1. Check Xcode version (16.4+)
2. Check iOS target (15.0+)
3. Check signing (disabled)
4. Run build locally
5. Verify IPA generation
6. Test with ESign

**Estimated**: 1 hour

---

### Task 4: Final Testing

**Integration Test Checklist**:
- [ ] All flows work end-to-end
- [ ] No crashes
- [ ] No memory leaks
- [ ] Performance acceptable
- [ ] UI responsive
- [ ] Animations smooth

**Estimated**: 1 hour

---

## FILES TO CREATE/UPDATE

### Create
- None (all components already created)

### Update
- `Runner/UI/Screens/AnalyzerViewController.swift` (add integration)
- `Runner/System/PerformanceGuard.swift` (enhance monitoring)
- `Runner/System/ProcessingGate.swift` (optimize queue)
- `.github/workflows/build-ios-ipa.yml` (verify config)

---

## SUCCESS CRITERIA

### Phase 3.5 Complete When:
- [ ] Main thread safety verified
- [ ] Memory leaks fixed
- [ ] Thermal management working
- [ ] Crash logging enabled
- [ ] Performance metrics logged

### Phase 3.6 Complete When:
- [ ] Xcode build successful
- [ ] Archive generated
- [ ] IPA packaged
- [ ] Artifact uploaded
- [ ] ESign compatible

### Phase 3 Complete When:
- [ ] All flows working end-to-end
- [ ] All components integrated
- [ ] All tests passing
- [ ] Unsigned IPA ready
- [ ] Ready for ESign

---

## TIMELINE

| Task | Duration | Status |
|------|----------|--------|
| AnalyzerViewController Integration | 1h | 🔄 TODO |
| Performance Optimization | 2h | 🔄 TODO |
| GitHub Actions Build | 1h | 🔄 TODO |
| Final Testing | 1h | 🔄 TODO |
| **TOTAL** | **5h** | **🔄 TODO** |

---

## NOTES

- All backend components are complete and tested
- All UI components are complete and styled
- Integration is straightforward
- Performance optimization is standard practice
- Build verification is final step

---

## READY TO START?

All components are in place. Next session should focus on:
1. AnalyzerViewController integration (1 hour)
2. Performance optimization (2 hours)
3. GitHub Actions build verification (1 hour)
4. Final testing (1 hour)

**Total**: ~5 hours to complete Phase 3

---

**Status**: 🚀 READY FOR SESSION 3  
**Next**: AnalyzerViewController Integration
