import UIKit

/// ChordPatternView displays detected chord with visualization and confidence indicator.
/// Uses liquid glass theme with real-time updates.
public class ChordPatternView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let glassBackgroundView = UIView()
    
    // Chord display
    private let chordNameLabel = UILabel()
    private let chordTypeLabel = UILabel()
    
    // Confidence indicator
    private let confidenceLabel = UILabel()
    private let confidenceBar = UIProgressView(progressViewStyle: .bar)
    
    // Chord diagram (12-note circle)
    private let chordDiagramView = UIView()
    private var noteCircles: [UIView] = []
    
    // Timestamp
    private let timestampLabel = UILabel()
    
    // MARK: - Properties
    
    private var currentChord: String = "C Major"
    private var currentConfidence: Float = 0.0
    private var currentTimestamp: TimeInterval = 0
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Glass background
        glassBackgroundView.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.1)
        glassBackgroundView.layer.cornerRadius = 16
        glassBackgroundView.layer.borderWidth = 1
        glassBackgroundView.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2).cgColor
        
        // Apply glass effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        glassBackgroundView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(glassBackgroundView)
        glassBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Container
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Chord name (large)
        chordNameLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        chordNameLabel.textColor = StudioTheme.colors.accentPurple
        chordNameLabel.text = "C Major"
        containerView.addSubview(chordNameLabel)
        chordNameLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        // Chord type (small)
        chordTypeLabel.font = StudioTheme.typography.label
        chordTypeLabel.textColor = StudioTheme.colors.textSecondary
        chordTypeLabel.text = "Major Triad"
        containerView.addSubview(chordTypeLabel)
        chordTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(chordNameLabel.snp.bottom).offset(4)
            make.left.equalToSuperview()
        }
        
        // Confidence label
        confidenceLabel.text = "Confidence"
        confidenceLabel.font = StudioTheme.typography.label
        confidenceLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(confidenceLabel)
        confidenceLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        // Confidence bar
        confidenceBar.progressTintColor = StudioTheme.colors.accentPurple
        confidenceBar.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        confidenceBar.progress = 0.75
        containerView.addSubview(confidenceBar)
        confidenceBar.snp.makeConstraints { make in
            make.top.equalTo(confidenceLabel.snp.bottom).offset(4)
            make.right.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(4)
        }
        
        // Chord diagram (12-note circle)
        setupChordDiagram()
        containerView.addSubview(chordDiagramView)
        chordDiagramView.snp.makeConstraints { make in
            make.top.equalTo(chordTypeLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }
        
        // Timestamp
        timestampLabel.text = "0:00"
        timestampLabel.font = StudioTheme.typography.label
        timestampLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(timestampLabel)
        timestampLabel.snp.makeConstraints { make in
            make.top.equalTo(chordDiagramView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupChordDiagram() {
        chordDiagramView.backgroundColor = .clear
        
        // Create 12 note circles (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let radius: CGFloat = 50
        let centerX: CGFloat = 60
        let centerY: CGFloat = 60
        
        for (index, note) in notes.enumerated() {
            let angle = CGFloat(index) * (2 * .pi / 12) - .pi / 2
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            // Note circle
            let circle = UIView()
            circle.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
            circle.layer.cornerRadius = 12
            circle.layer.borderWidth = 1
            circle.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3).cgColor
            chordDiagramView.addSubview(circle)
            circle.snp.makeConstraints { make in
                make.width.height.equalTo(24)
                make.centerX.equalToSuperview().offset(x - centerX)
                make.centerY.equalToSuperview().offset(y - centerY)
            }
            
            // Note label
            let label = UILabel()
            label.text = note
            label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
            label.textColor = StudioTheme.colors.textSecondary
            label.textAlignment = .center
            circle.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            noteCircles.append(circle)
        }
        
        // Center circle
        let centerCircle = UIView()
        centerCircle.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
        centerCircle.layer.cornerRadius = 15
        chordDiagramView.addSubview(centerCircle)
        centerCircle.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.center.equalToSuperview()
        }
        
        let centerLabel = UILabel()
        centerLabel.text = "ROOT"
        centerLabel.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        centerLabel.textColor = StudioTheme.colors.accentPurple
        centerLabel.textAlignment = .center
        centerCircle.addSubview(centerLabel)
        centerLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public API
    
    /// Update chord display with new detection result
    public func updateChord(
        name: String,
        type: String,
        confidence: Float,
        timestamp: TimeInterval
    ) {
        currentChord = name
        currentConfidence = confidence
        currentTimestamp = timestamp
        
        // Animate update
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.chordNameLabel.text = name
            self.chordTypeLabel.text = type
            self.confidenceBar.progress = confidence
            self.timestampLabel.text = self.formatTime(timestamp)
            
            // Highlight chord notes
            self.highlightChordNotes(for: name)
        })
    }
    
    /// Highlight notes that are part of the chord
    private func highlightChordNotes(for chordName: String) {
        // Reset all circles
        for circle in noteCircles {
            circle.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
            circle.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3).cgColor
        }
        
        // Get chord intervals
        let chordTheory = ChordTheory.shared
        let intervals = chordTheory.getChordIntervals(for: chordName)
        
        // Highlight chord notes
        for interval in intervals {
            if interval < noteCircles.count {
                let circle = noteCircles[interval]
                circle.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.6)
                circle.layer.borderColor = StudioTheme.colors.accentPurple.cgColor
                circle.layer.borderWidth = 2
            }
        }
    }
    
    /// Format time interval to MM:SS
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    /// Set confidence with animation
    public func setConfidence(_ value: Float) {
        UIView.animate(withDuration: 0.3) {
            self.confidenceBar.progress = value
        }
    }
    
    /// Clear display
    public func clear() {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.chordNameLabel.text = "—"
            self.chordTypeLabel.text = "No chord detected"
            self.confidenceBar.progress = 0
            self.timestampLabel.text = "0:00"
            
            // Reset all circles
            for circle in self.noteCircles {
                circle.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
                circle.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3).cgColor
                circle.layer.borderWidth = 1
            }
        })
    }
}

// MARK: - ChordTheory Extension

extension ChordTheory {
    
    /// Get intervals (note indices) for a chord
    func getChordIntervals(for chordName: String) -> [Int] {
        // Parse chord name (e.g., "C Major" -> root: 0, type: Major)
        let components = chordName.split(separator: " ")
        guard let rootNote = components.first else { return [] }
        
        let rootIndex = noteToIndex(String(rootNote))
        
        // Get chord intervals based on type
        let intervals: [Int]
        if components.count > 1 {
            let chordType = String(components[1])
            intervals = getIntervals(for: chordType)
        } else {
            intervals = [0, 4, 7]  // Default major triad
        }
        
        // Transpose intervals to root note
        return intervals.map { ($0 + rootIndex) % 12 }
    }
    
    private func noteToIndex(_ note: String) -> Int {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return notes.firstIndex(of: note) ?? 0
    }
    
    private func getIntervals(for chordType: String) -> [Int] {
        switch chordType {
        case "Major":
            return [0, 4, 7]
        case "Minor":
            return [0, 3, 7]
        case "Diminished":
            return [0, 3, 6]
        case "Augmented":
            return [0, 4, 8]
        case "7th":
            return [0, 4, 7, 10]
        case "Major7":
            return [0, 4, 7, 11]
        case "Minor7":
            return [0, 3, 7, 10]
        case "Suspended2":
            return [0, 2, 7]
        case "Suspended4":
            return [0, 5, 7]
        case "Add9":
            return [0, 4, 7, 14]
        case "Diminished7":
            return [0, 3, 6, 9]
        case "HalfDiminished":
            return [0, 3, 6, 10]
        default:
            return [0, 4, 7]
        }
    }
}
