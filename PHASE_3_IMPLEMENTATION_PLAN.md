# Phase 3 — Integration, Optimization, Export, and Build IPA

**Status**: 🚀 IN PROGRESS  
**Target**: Unsigned IPA ready for ESign  
**Date Started**: June 1, 2026

---

## Phase 3 Objectives

### Primary Goals
1. ✅ **End-to-End Integration** - All flows connected and working
2. ✅ **Export System** - M4A mix + individual stems export
3. ✅ **On-Demand Analysis** - Chord/beat analysis manual trigger
4. ✅ **Performance Optimization** - No blocking, no memory leaks
5. ✅ **Unsigned IPA Build** - Ready for ESign distribution

---

## Implementation Roadmap

### Phase 3.1 — Export System (CRITICAL)
**Priority**: 🔴 HIGHEST  
**Estimated**: 2-3 hours

#### Files to Create
1. **ExportManager.swift** - Core export logic
   - Stereo mix export (M4A)
   - Individual stem export
   - Batch export
   - Progress tracking
   - Temp file cleanup

2. **ExportViewController.swift** - Export UI
   - Format selection (M4A, WAV, FLAC)
   - Quality settings
   - Progress display
   - Share to Files app
   - Save to project folder

#### Integration Points
- ResultViewController → ExportManager
- MixerViewController → ExportManager
- ProfileViewController → ExportManager

#### Checklist
- [ ] ExportManager.swift created
- [ ] ExportViewController.swift created
- [ ] M4A export working
- [ ] Stem export working
- [ ] Progress tracking working
- [ ] Temp cleanup working
- [ ] Share to Files working

---

### Phase 3.2 — Recording Module (HIGH)
**Priority**: 🟠 HIGH  
**Estimated**: 2 hours

#### Files to Update
1. **RecordingViewController.swift** - Complete implementation
   - Audio recording setup
   - Video recording setup
   - Real-time level metering
   - Recording state management
   - File saving to ProjectStore

2. **AudioEngineManager.swift** - Add recording node
   - AVAudioInputNode setup
   - Recording buffer management
   - File writing

#### Integration Points
- RecordingViewController → AudioEngineManager
- RecordingViewController → ProjectStore
- ProcessingGate → recording operation

#### Checklist
- [ ] Audio recording working
- [ ] Video recording working
- [ ] Level metering working
- [ ] File saving working
- [ ] ProjectStore integration working

---

### Phase 3.3 — Analysis On-Demand (HIGH)
**Priority**: 🟠 HIGH  
**Estimated**: 2 hours

#### Files to Update
1. **AnalyzerViewController.swift** - Manual trigger
   - Chord analysis button
   - Beat analysis button
   - Lyrics sync button
   - Progress display
   - Result caching

2. **ChordDetectionManager.swift** - Real inference
   - Chromagram extraction
   - Chord inference (Chordcrnn model)
   - Confidence scoring

3. **BeatDetectionManager.swift** - Real inference
   - Log-mel spectrogram
   - BPM detection (convtcn20 model)
   - Beat timing extraction

#### Integration Points
- AnalyzerViewController → ChordDetectionManager
- AnalyzerViewController → BeatDetectionManager
- ProcessingGate → analysis operations

#### Checklist
- [ ] Chord analysis on-demand working
- [ ] Beat analysis on-demand working
- [ ] Lyrics sync working
- [ ] Result caching working
- [ ] Progress display working

---

### Phase 3.4 — UI Components (MEDIUM)
**Priority**: 🟡 MEDIUM  
**Estimated**: 2 hours

#### Files to Create/Update
1. **ChordPatternView.swift** - Chord visualization
2. **ChordTimelineView.swift** - Chord timeline
3. **BeatGridView.swift** - Beat grid display
4. **LyricsKaraokeView.swift** - Lyrics sync display
5. **StemChannelView.swift** - Stem channel control
6. **ProcessingStageRowView.swift** - Processing stage display

#### Checklist
- [ ] All components implemented
- [ ] All components integrated
- [ ] All components styled
- [ ] All components tested

---

### Phase 3.5 — Performance Optimization (MEDIUM)
**Priority**: 🟡 MEDIUM  
**Estimated**: 2 hours

#### Optimization Checklist
- [ ] No blocking main thread
- [ ] No full PCM sent to UI
- [ ] No repeated model loading
- [ ] Progress throttled
- [ ] Memory cleanup after processing
- [ ] Thermal warning active
- [ ] Crash log readable

#### Files to Update
1. **PerformanceGuard.swift** - Enhanced monitoring
2. **ProcessingGate.swift** - Better queue management
3. **AudioEngineManager.swift** - Memory pooling
4. **ModelManager.swift** - Model caching optimization

#### Checklist
- [ ] Main thread blocking eliminated
- [ ] Memory leaks fixed
- [ ] Thermal throttling handled
- [ ] Crash logs readable
- [ ] Performance metrics logged

---

### Phase 3.6 — GitHub Actions Build (FINAL)
**Priority**: 🟢 FINAL  
**Estimated**: 1 hour

#### Build Configuration
- [ ] Xcode 16.4 selected
- [ ] iOS deployment target correct
- [ ] CODE_SIGNING_ALLOWED=NO set
- [ ] Archive successful
- [ ] IPA packaging successful
- [ ] Artifact upload working

#### Checklist
- [ ] Build workflow runs successfully
- [ ] IPA generated correctly
- [ ] Artifact uploaded
- [ ] Ready for ESign

---

## Integration Flows

### Flow 1: Import → Processing → Result → Mixer
```
HomeViewController
  ↓ (tap "Import Audio")
ImportSourceViewController
  ↓ (select file)
ProcessingViewController
  ↓ (run separation)
ResultViewController
  ↓ (preview stems)
MixerViewController
  ↓ (mix stems)
ExportViewController
  ↓ (export mix)
Files App / ProjectStore
```

### Flow 2: Recording → Save → Mixer
```
RecordingViewController
  ↓ (record audio/video)
ProjectStore
  ↓ (save session)
MixerViewController
  ↓ (load recording)
AnalyzerViewController
  ↓ (analyze)
ExportViewController
  ↓ (export)
```

### Flow 3: Mixer → Analyzer → Export
```
MixerViewController
  ↓ (play mix)
AnalyzerViewController
  ↓ (analyze on-demand)
  ├→ Chord analysis
  ├→ Beat analysis
  └→ Lyrics sync
ExportViewController
  ↓ (export with metadata)
```

---

## Export System Details

### ExportManager.swift Structure
```swift
class ExportManager {
    // Export formats
    enum ExportFormat {
        case m4a(quality: AudioQuality)
        case wav
        case flac
        case mp3(bitrate: Int)
    }
    
    // Export operations
    func exportStereoMix(
        from project: StemProject,
        format: ExportFormat,
        progress: @escaping (Float) -> Void
    ) -> URL
    
    func exportIndividualStems(
        from project: StemProject,
        format: ExportFormat,
        progress: @escaping (Float) -> Void
    ) -> [String: URL]
    
    func exportBatch(
        from projects: [StemProject],
        format: ExportFormat,
        progress: @escaping (Float) -> Void
    ) -> [URL]
    
    // Cleanup
    func cleanupTempFiles()
}
```

### Export Flow
1. User selects export format
2. ExportManager creates temp files
3. AudioEngineManager mixes stems
4. AVAudioFile writes to disk
5. Progress updates UI
6. Share to Files app or save to project
7. Cleanup temp files

---

## Performance Optimization Checklist

### Main Thread Safety
- [ ] All UI updates on main thread
- [ ] All heavy operations on background thread
- [ ] No blocking operations on main thread
- [ ] Proper thread synchronization

### Memory Management
- [ ] No memory leaks (Instruments verified)
- [ ] Proper cleanup after processing
- [ ] Audio buffer pooling
- [ ] Model caching optimization
- [ ] Temp file cleanup

### Audio Processing
- [ ] No full PCM sent to UI
- [ ] Downsampled waveforms for display
- [ ] Cached analysis results
- [ ] Efficient STFT/iSTFT
- [ ] GPU acceleration where possible

### Thermal Management
- [ ] Thermal state monitoring
- [ ] Operation throttling on high temp
- [ ] User warning display
- [ ] Graceful degradation

### Crash Logging
- [ ] Readable crash logs
- [ ] Stack traces captured
- [ ] Error context preserved
- [ ] Recovery mechanisms

---

## Testing Checklist

### Import Flow
- [ ] Audio file import working
- [ ] Video file import working
- [ ] File validation working
- [ ] Sandbox copy working
- [ ] Error handling working

### Processing Flow
- [ ] Separation running
- [ ] Progress tracking working
- [ ] Thermal throttling working
- [ ] Error recovery working
- [ ] Result saving working

### Mixer Flow
- [ ] 6 stems loading
- [ ] Playback working
- [ ] Volume control working
- [ ] Mute/solo working
- [ ] Waveform display working

### Analyzer Flow
- [ ] Chord analysis on-demand
- [ ] Beat analysis on-demand
- [ ] Lyrics sync working
- [ ] Result caching working
- [ ] Progress display working

### Export Flow
- [ ] M4A export working
- [ ] Stem export working
- [ ] Progress tracking working
- [ ] Share to Files working
- [ ] Temp cleanup working

### Recording Flow
- [ ] Audio recording working
- [ ] Video recording working
- [ ] Level metering working
- [ ] File saving working
- [ ] ProjectStore integration working

### Build Flow
- [ ] Xcode build successful
- [ ] Archive successful
- [ ] IPA generation successful
- [ ] Artifact upload successful
- [ ] Ready for ESign

---

## Success Criteria

### Phase 3 Complete When:
✅ Import audio/video working  
✅ Separation working  
✅ Mixer can play 6 stems  
✅ Mute/solo/volume active  
✅ Analyzer can display chord/beat/lyrics  
✅ Recording can save file  
✅ Export M4A/stem working  
✅ Project saved  
✅ Cache can be cleared  
✅ Build unsigned IPA successful  

---

## Timeline

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| 3.1 | Export System | 2-3h | 🔴 TODO |
| 3.2 | Recording Module | 2h | 🔴 TODO |
| 3.3 | Analysis On-Demand | 2h | 🔴 TODO |
| 3.4 | UI Components | 2h | 🔴 TODO |
| 3.5 | Performance Optimization | 2h | 🔴 TODO |
| 3.6 | GitHub Actions Build | 1h | 🔴 TODO |
| **TOTAL** | **Phase 3** | **~11-12h** | **🔴 TODO** |

---

## Next Steps

1. ✅ Create ExportManager.swift
2. ✅ Create ExportViewController.swift
3. ✅ Update RecordingViewController.swift
4. ✅ Update ChordDetectionManager.swift
5. ✅ Update BeatDetectionManager.swift
6. ✅ Implement UI components
7. ✅ Performance optimization
8. ✅ GitHub Actions build verification
9. ✅ Final testing
10. ✅ IPA generation

---

**Status**: 🚀 READY TO START  
**Next**: Create ExportManager.swift
