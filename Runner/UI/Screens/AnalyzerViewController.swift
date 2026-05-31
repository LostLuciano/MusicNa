import UIKit

/// AI Analyzer screen - chords, beat, lyrics analysis with real-time detection
public class AnalyzerViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Tab control
    private let tabControl = UISegmentedControl(items: ["Chords", "Beat", "Lyrics"])
    
    // Chord tab
    private let chordPatternView = ChordPatternView()
    private let chordTimelineView = ChordTimelineView()
    private let analyzeChordButton = PurpleGlowButton()
    private let chordProgressView = UIProgressView(progressViewStyle: .bar)
    
    // Beat tab
    private let beatGridView = BeatGridView()
    private let analyzeBeatButton = PurpleGlowButton()
    private let beatProgressView = UIProgressView(progressViewStyle: .bar)
    
    // Lyrics tab
    private let lyricsView = LyricsKaraokeView()
    private let syncLyricsButton = PurpleGlowButton()
    private let emptyLyricsLabel = UILabel()
    
    // Managers
    private let projectStore = ProjectStore.shared
    private let chordManager = ChordDetectionManager.shared
    private let beatManager = BeatDetectionManager.shared
    private let audioEngine = AudioEngineManager()
    
    public var project: StemProject?
    private var selectedTab: Int = 0
    private var isAnalyzing = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlaybackSync()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chordManager.cancelDetection()
        beatManager.cancelDetection()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "AI Analyzer", subtitle: "Music Analysis")
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        // Tab control
        tabControl.selectedSegmentIndex = 0
        tabControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        contentView.addSubview(tabControl)
        tabControl.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        // Setup tabs
        setupChordTab()
        setupBeatTab()
        setupLyricsTab()
        
        // Show first tab
        showTab(0)
    }
    
    private func setupChordTab() {
        // Pattern view
        contentView.addSubview(chordPatternView)
        chordPatternView.snp.makeConstraints { make in
            make.top.equalTo(tabControl.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        // Timeline
        contentView.addSubview(chordTimelineView)
        chordTimelineView.snp.makeConstraints { make in
            make.top.equalTo(chordPatternView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
        
        // Progress
        chordProgressView.progressTintColor = StudioTheme.colors.accentPurple
        chordProgressView.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        chordProgressView.isHidden = true
        contentView.addSubview(chordProgressView)
        chordProgressView.snp.makeConstraints { make in
            make.top.equalTo(chordTimelineView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(4)
        }
        
        // Analyze button
        analyzeChordButton.setTitle("🎵 Analyze Chords", for: .normal)
        analyzeChordButton.addTarget(self, action: #selector(analyzeChords), for: .touchUpInside)
        contentView.addSubview(analyzeChordButton)
        analyzeChordButton.snp.makeConstraints { make in
            make.top.equalTo(chordProgressView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    private func setupBeatTab() {
        // Beat grid
        contentView.addSubview(beatGridView)
        beatGridView.snp.makeConstraints { make in
            make.top.equalTo(tabControl.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        // Progress
        beatProgressView.progressTintColor = StudioTheme.colors.accentPurple
        beatProgressView.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        beatProgressView.isHidden = true
        contentView.addSubview(beatProgressView)
        beatProgressView.snp.makeConstraints { make in
            make.top.equalTo(beatGridView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(4)
        }
        
        // Analyze button
        analyzeBeatButton.setTitle("🎯 Analyze Beat", for: .normal)
        analyzeBeatButton.addTarget(self, action: #selector(analyzeBeats), for: .touchUpInside)
        contentView.addSubview(analyzeBeatButton)
        analyzeBeatButton.snp.makeConstraints { make in
            make.top.equalTo(beatProgressView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    private func setupLyricsTab() {
        // Lyrics view
        contentView.addSubview(lyricsView)
        lyricsView.snp.makeConstraints { make in
            make.top.equalTo(tabControl.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        // Empty state
        emptyLyricsLabel.text = "No lyrics available for this track"
        emptyLyricsLabel.font = StudioTheme.typography.body
        emptyLyricsLabel.textColor = StudioTheme.colors.textSecondary
        emptyLyricsLabel.textAlignment = .center
        contentView.addSubview(emptyLyricsLabel)
        emptyLyricsLabel.snp.makeConstraints { make in
            make.top.equalTo(tabControl.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }
        
        // Sync button
        syncLyricsButton.setTitle("🎤 Sync Lyrics", for: .normal)
        syncLyricsButton.addTarget(self, action: #selector(syncLyrics), for: .touchUpInside)
        contentView.addSubview(syncLyricsButton)
        syncLyricsButton.snp.makeConstraints { make in
            make.top.equalTo(lyricsView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    @objc private func tabChanged(_ sender: UISegmentedControl) {
        selectedTab = sender.selectedSegmentIndex
        showTab(selectedTab)
    }
    
    private func showTab(_ index: Int) {
        // Hide all
        chordPatternView.isHidden = true
        chordTimelineView.isHidden = true
        analyzeChordButton.isHidden = true
        chordProgressView.isHidden = true
        
        beatGridView.isHidden = true
        analyzeBeatButton.isHidden = true
        beatProgressView.isHidden = true
        
        lyricsView.isHidden = true
        emptyLyricsLabel.isHidden = true
        syncLyricsButton.isHidden = true
        
        // Show selected
        switch index {
        case 0:  // Chords
            chordPatternView.isHidden = false
            chordTimelineView.isHidden = false
            analyzeChordButton.isHidden = false
        case 1:  // Beat
            beatGridView.isHidden = false
            analyzeBeatButton.isHidden = false
        case 2:  // Lyrics
            lyricsView.isHidden = false
            emptyLyricsLabel.isHidden = false
            syncLyricsButton.isHidden = false
        default:
            break
        }
    }
    
    @objc private func analyzeChords() {
        guard let project = project, let audioURL = project.originalAudioURL else {
            showAlert(title: "Error", message: "No audio file loaded")
            return
        }
        
        guard !isAnalyzing else {
            showAlert(title: "Analyzing", message: "Analysis already in progress")
            return
        }
        
        isAnalyzing = true
        analyzeChordButton.isEnabled = false
        chordProgressView.isHidden = false
        chordProgressView.progress = 0
        
        DispatchQueue.main.async {
            self.chordManager.detectChords(from: audioURL, progress: { progress in
                DispatchQueue.main.async {
                    self.chordProgressView.progress = progress
                }
            }, completion: { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analyzeChordButton.isEnabled = true
                    self.chordProgressView.isHidden = true
                    
                    switch result {
                    case .success(let chords):
                        if !chords.isEmpty {
                            // Display first chord
                            let firstChord = chords[0]
                            self.chordPatternView.updateChord(
                                name: firstChord.chord,
                                type: "Detected",
                                confidence: firstChord.confidence,
                                timestamp: firstChord.timestamp
                            )
                            
                            // Load timeline
                            let segments = chords.map { chord in
                                ChordTimelineView.ChordSegment(
                                    chord: chord.chord,
                                    startTime: chord.timestamp,
                                    duration: chord.duration,
                                    confidence: chord.confidence
                                )
                            }
                            self.chordTimelineView.loadChords(segments)
                            
                            Logger.shared.info("Detected \(chords.count) chords")
                        }
                    case .failure(let error):
                        self.showAlert(title: "Analysis Failed", message: error.localizedDescription)
                        Logger.shared.error("Chord analysis failed: \(error)")
                    }
                }
            })
        }
    }
    
    @objc private func analyzeBeats() {
        guard let project = project, let audioURL = project.originalAudioURL else {
            showAlert(title: "Error", message: "No audio file loaded")
            return
        }
        
        guard !isAnalyzing else {
            showAlert(title: "Analyzing", message: "Analysis already in progress")
            return
        }
        
        isAnalyzing = true
        analyzeBeatButton.isEnabled = false
        beatProgressView.isHidden = false
        beatProgressView.progress = 0
        
        DispatchQueue.main.async {
            self.beatManager.detectBeats(from: audioURL, progress: { progress in
                DispatchQueue.main.async {
                    self.beatProgressView.progress = progress
                }
            }, completion: { result in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.analyzeBeatButton.isEnabled = true
                    self.beatProgressView.isHidden = true
                    
                    switch result {
                    case .success(let beats):
                        self.beatGridView.updateBeats(
                            bpm: beats.bpm,
                            timeSignature: beats.timeSignature,
                            beats: beats.beats,
                            confidence: beats.confidence
                        )
                        Logger.shared.info("Detected \(beats.beats.count) beats at \(beats.bpm) BPM")
                    case .failure(let error):
                        self.showAlert(title: "Analysis Failed", message: error.localizedDescription)
                        Logger.shared.error("Beat analysis failed: \(error)")
                    }
                }
            })
        }
    }
    
    @objc private func syncLyrics() {
        showAlert(title: "Lyrics", message: "Lyrics sync coming soon")
    }
    
    private func setupPlaybackSync() {
        // Sync UI with playback time
        // This would be called from MixerViewController or playback manager
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
        
        // Analyze button
        analyzeChordButton.setTitle("Analyze Chords", font: Typography.labelLarge)
        analyzeChordButton.addTarget(self, action: #selector(analyzeChordsTapped), for: .touchUpInside)
        containerView.addSubview(analyzeChordButton)
        
        analyzeChordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            analyzeChordButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            analyzeChordButton.topAnchor.constraint(equalTo: chordTimelineView.bottomAnchor, constant: 16),
            analyzeChordButton.widthAnchor.constraint(equalToConstant: 200),
            analyzeChordButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func setupBeatTab() {
        // BPM label
        bpmLabel.font = Typography.displayLarge
        bpmLabel.textColor = StudioColors.purpleAccent
        bpmLabel.textAlignment = .center
        containerView.addSubview(bpmLabel)
        
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bpmLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bpmLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16)
        ])
        
        // Confidence label
        confidenceLabel.font = Typography.labelMedium
        confidenceLabel.textColor = StudioColors.textSecondary
        confidenceLabel.textAlignment = .center
        containerView.addSubview(confidenceLabel)
        
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            confidenceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            confidenceLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 8)
        ])
        
        // Beat grid
        beatGridView.setupGlassCard()
        containerView.addSubview(beatGridView)
        
        beatGridView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            beatGridView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            beatGridView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            beatGridView.topAnchor.constraint(equalTo: confidenceLabel.bottomAnchor, constant: 16),
            beatGridView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Metronome toggle
        metronomeToggle.onTintColor = StudioColors.purpleAccent
        metronomeToggle.addTarget(self, action: #selector(metronomeTapped), for: .valueChanged)
        containerView.addSubview(metronomeToggle)
        
        metronomeToggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metronomeToggle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            metronomeToggle.topAnchor.constraint(equalTo: beatGridView.bottomAnchor, constant: 16)
        ])
    }
    
    private func setupLyricsTab() {
        // Lyrics view
        lyricsView.setupGlassCard()
        containerView.addSubview(lyricsView)
        
        lyricsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lyricsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            lyricsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            lyricsView.topAnchor.constraint(equalTo: containerView.topAnchor),
            lyricsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Empty state
        emptyLyricsState.title = "No Lyrics Available"
        emptyLyricsState.message = "Lyrics are not available for this track"
        containerView.addSubview(emptyLyricsState)
        
        emptyLyricsState.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLyricsState.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            emptyLyricsState.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            emptyLyricsState.topAnchor.constraint(equalTo: containerView.topAnchor),
            emptyLyricsState.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func loadAnalysisData() {
        guard let project = project else { return }
        
        // Load chord data
        if let chordData = project.chordData {
            updateChordDisplay(chordData)
        }
        
        // Load beat data
        if let beatData = project.beatData {
            updateBeatDisplay(beatData)
        }
    }
    
    private func updateChordDisplay(_ data: ChordAnalysis) {
        guard let firstChord = data.chords.first else { return }
        
        chordPatternView.chordName = firstChord.name
        chordPatternView.confidence = data.confidence
        
        // Convert chords to timeline
        let timelineChords = data.chords.map { chord in
            ChordTimelineView.ChordSegment(
                name: chord.name,
                startTime: chord.startTime,
                endTime: chord.endTime
            )
        }
        chordTimelineView.chords = timelineChords
    }
    
    private func updateBeatDisplay(_ data: BeatAnalysis) {
        bpmLabel.text = String(format: "%.0f BPM", data.bpm)
        confidenceLabel.text = String(format: "Confidence: %.0f%%", data.confidence * 100)
        
        beatGridView.beats = data.beats
        beatGridView.duration = data.beats.last ?? 0
    }
    
    @objc private func tabChanged(_ sender: UISegmentedControl) {
        showTab(sender.selectedSegmentIndex)
    }
    
    private func showTab(_ index: Int) {
        // Hide all
        chordPatternView.isHidden = true
        chordTimelineView.isHidden = true
        analyzeChordButton.isHidden = true
        bpmLabel.isHidden = true
        confidenceLabel.isHidden = true
        beatGridView.isHidden = true
        metronomeToggle.isHidden = true
        lyricsView.isHidden = true
        emptyLyricsState.isHidden = true
        
        // Show selected
        switch index {
        case 0: // Chords
            chordPatternView.isHidden = false
            chordTimelineView.isHidden = false
            analyzeChordButton.isHidden = false
        case 1: // Beat
            bpmLabel.isHidden = false
            confidenceLabel.isHidden = false
            beatGridView.isHidden = false
            metronomeToggle.isHidden = false
        case 2: // Lyrics
            lyricsView.isHidden = false
            emptyLyricsState.isHidden = false
        default:
            break
        }
    }
    
    @objc private func analyzeChordsTapped() {
        showAlert(title: "Analyzing", message: "Chord analysis in progress...")
    }
    
    @objc private func metronomeTapped() {
        if metronomeToggle.isOn {
            Logger.shared.info("Metronome enabled")
        } else {
            Logger.shared.info("Metronome disabled")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ChordTimelineDelegate

extension AnalyzerViewController: ChordTimelineDelegate {
    
    func chordTimeline(_ timeline: ChordTimelineView, didSelectChordAt time: TimeInterval) {
        Logger.shared.info("Seeking to chord at \(time)s")
    }
}
