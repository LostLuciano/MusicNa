import UIKit

/// ChordTimelineView displays chord progression over time with playhead indicator.
/// Shows chord changes and allows seeking through the timeline.
public class ChordTimelineView: UIView {
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let timelineView = UIView()
    private let playheadView = UIView()
    private let playheadLabel = UILabel()
    
    // Chord segments
    private var chordSegments: [ChordSegmentView] = []
    
    // Time markers
    private let timeMarkerStackView = UIStackView()
    
    // MARK: - Properties
    
    private var chords: [ChordSegment] = []
    private var totalDuration: TimeInterval = 0
    private var currentTime: TimeInterval = 0
    private var isPlaying = false
    
    public struct ChordSegment {
        public let chord: String
        public let startTime: TimeInterval
        public let duration: TimeInterval
        public let confidence: Float
        
        public init(chord: String, startTime: TimeInterval, duration: TimeInterval, confidence: Float) {
            self.chord = chord
            self.startTime = startTime
            self.duration = duration
            self.confidence = confidence
        }
    }
    
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
        
        // Scroll view
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Content view
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.height.equalTo(scrollView)
        }
        
        // Timeline background
        let timelineBackground = UIView()
        timelineBackground.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.05)
        timelineBackground.layer.cornerRadius = 8
        contentView.addSubview(timelineBackground)
        timelineBackground.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(8)
            make.height.equalTo(80)
        }
        
        // Timeline view
        timelineView.backgroundColor = .clear
        contentView.addSubview(timelineView)
        timelineView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(8)
            make.height.equalTo(80)
        }
        
        // Playhead
        playheadView.backgroundColor = StudioTheme.colors.accentPurple
        playheadView.layer.cornerRadius = 2
        contentView.addSubview(playheadView)
        playheadView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(4)
            make.height.equalTo(80)
            make.left.equalToSuperview().offset(8)
        }
        
        // Playhead label
        playheadLabel.text = "0:00"
        playheadLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        playheadLabel.textColor = StudioTheme.colors.accentPurple
        playheadLabel.textAlignment = .center
        contentView.addSubview(playheadLabel)
        playheadLabel.snp.makeConstraints { make in
            make.top.equalTo(playheadView.snp.bottom).offset(4)
            make.centerX.equalTo(playheadView)
            make.width.equalTo(40)
        }
        
        // Time markers
        timeMarkerStackView.axis = .horizontal
        timeMarkerStackView.distribution = .equalSpacing
        timeMarkerStackView.alignment = .center
        contentView.addSubview(timeMarkerStackView)
        timeMarkerStackView.snp.makeConstraints { make in
            make.top.equalTo(playheadLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview().inset(8)
            make.height.equalTo(20)
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(timelineTapped(_:)))
        timelineView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public API
    
    /// Load chord segments
    public func loadChords(_ segments: [ChordSegment]) {
        chords = segments
        
        guard !segments.isEmpty else {
            totalDuration = 0
            return
        }
        
        // Calculate total duration
        totalDuration = segments.map { $0.startTime + $0.duration }.max() ?? 0
        
        // Clear existing segments
        chordSegments.forEach { $0.removeFromSuperview() }
        chordSegments.removeAll()
        
        // Create segment views
        for segment in segments {
            let segmentView = ChordSegmentView()
            segmentView.configure(
                chord: segment.chord,
                confidence: segment.confidence
            )
            timelineView.addSubview(segmentView)
            
            // Calculate position and width
            let startX = (segment.startTime / totalDuration) * 300  // 300pt timeline width
            let width = (segment.duration / totalDuration) * 300
            
            segmentView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(startX)
                make.width.equalTo(max(width, 20))  // Minimum width
            }
            
            chordSegments.append(segmentView)
        }
        
        // Update content width
        contentView.snp.updateConstraints { make in
            make.width.equalTo(max(300, (totalDuration / 60) * 50))  // Scale based on duration
        }
        
        // Add time markers
        updateTimeMarkers()
    }
    
    /// Update playhead position
    public func updatePlayhead(time: TimeInterval) {
        currentTime = time
        
        let progress = totalDuration > 0 ? time / totalDuration : 0
        let playheadX = progress * 300  // 300pt timeline width
        
        playheadView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(8 + playheadX)
        }
        
        playheadLabel.text = formatTime(time)
        
        // Scroll to keep playhead visible
        let targetOffset = max(0, playheadX - 100)
        scrollView.setContentOffset(CGPoint(x: targetOffset, y: 0), animated: true)
    }
    
    /// Set playing state
    public func setPlaying(_ playing: Bool) {
        isPlaying = playing
    }
    
    /// Clear timeline
    public func clear() {
        chords.removeAll()
        chordSegments.forEach { $0.removeFromSuperview() }
        chordSegments.removeAll()
        totalDuration = 0
        currentTime = 0
        playheadLabel.text = "0:00"
    }
    
    // MARK: - Private Methods
    
    private func updateTimeMarkers() {
        timeMarkerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add markers every 30 seconds
        let interval: TimeInterval = 30
        var time: TimeInterval = 0
        
        while time <= totalDuration {
            let label = UILabel()
            label.text = formatTime(time)
            label.font = UIFont.systemFont(ofSize: 9, weight: .regular)
            label.textColor = StudioTheme.colors.textSecondary
            label.textAlignment = .center
            timeMarkerStackView.addArrangedSubview(label)
            
            time += interval
        }
    }
    
    @objc private func timelineTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: timelineView)
        let progress = location.x / timelineView.bounds.width
        let seekTime = progress * totalDuration
        
        // Notify delegate or callback
        updatePlayhead(time: seekTime)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - ChordSegmentView

private class ChordSegmentView: UIView {
    
    private let chordLabel = UILabel()
    private let confidenceBar = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
        layer.cornerRadius = 4
        layer.borderWidth = 1
        layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.5).cgColor
        
        // Chord label
        chordLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        chordLabel.textColor = StudioTheme.colors.accentPurple
        chordLabel.textAlignment = .center
        addSubview(chordLabel)
        chordLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(4)
        }
        
        // Confidence bar
        confidenceBar.backgroundColor = StudioTheme.colors.accentPurple
        confidenceBar.layer.cornerRadius = 2
        addSubview(confidenceBar)
        confidenceBar.snp.makeConstraints { make in
            make.top.equalTo(chordLabel.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview().inset(4)
            make.height.equalTo(3)
        }
    }
    
    func configure(chord: String, confidence: Float) {
        chordLabel.text = chord
        
        // Update confidence bar width
        confidenceBar.snp.updateConstraints { make in
            make.width.equalToSuperview().multipliedBy(CGFloat(confidence))
        }
    }
}
