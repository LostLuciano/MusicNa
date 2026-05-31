import UIKit

/// BeatGridView displays beat grid with BPM, time signature, and beat markers.
/// Shows real-time beat detection with visual feedback.
public class BeatGridView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let glassBackgroundView = UIView()
    
    // BPM display
    private let bpmLabel = UILabel()
    private let bpmValueLabel = UILabel()
    
    // Time signature
    private let timeSignatureLabel = UILabel()
    private let timeSignatureValueLabel = UILabel()
    
    // Confidence
    private let confidenceLabel = UILabel()
    private let confidenceBar = UIProgressView(progressViewStyle: .bar)
    
    // Beat grid
    private let beatGridView = UIView()
    private var beatMarkers: [UIView] = []
    
    // Current beat indicator
    private let currentBeatView = UIView()
    
    // MARK: - Properties
    
    private var bpm: Float = 0
    private var timeSignature: String = "4/4"
    private var beats: [TimeInterval] = []
    private var currentBeatIndex: Int = 0
    private var confidence: Float = 0
    
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
        
        // BPM display
        bpmLabel.text = "BPM"
        bpmLabel.font = StudioTheme.typography.label
        bpmLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(bpmLabel)
        bpmLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        bpmValueLabel.text = "—"
        bpmValueLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        bpmValueLabel.textColor = StudioTheme.colors.accentPurple
        containerView.addSubview(bpmValueLabel)
        bpmValueLabel.snp.makeConstraints { make in
            make.top.equalTo(bpmLabel.snp.bottom).offset(4)
            make.left.equalToSuperview()
        }
        
        // Time signature
        timeSignatureLabel.text = "Time Signature"
        timeSignatureLabel.font = StudioTheme.typography.label
        timeSignatureLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(timeSignatureLabel)
        timeSignatureLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        timeSignatureValueLabel.text = "4/4"
        timeSignatureValueLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        timeSignatureValueLabel.textColor = StudioTheme.colors.accentPurple
        containerView.addSubview(timeSignatureValueLabel)
        timeSignatureValueLabel.snp.makeConstraints { make in
            make.top.equalTo(timeSignatureLabel.snp.bottom).offset(4)
            make.right.equalToSuperview()
        }
        
        // Confidence
        confidenceLabel.text = "Confidence"
        confidenceLabel.font = StudioTheme.typography.label
        confidenceLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(confidenceLabel)
        confidenceLabel.snp.makeConstraints { make in
            make.top.equalTo(bpmValueLabel.snp.bottom).offset(16)
            make.left.equalToSuperview()
        }
        
        confidenceBar.progressTintColor = StudioTheme.colors.accentPurple
        confidenceBar.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        containerView.addSubview(confidenceBar)
        confidenceBar.snp.makeConstraints { make in
            make.top.equalTo(confidenceLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.height.equalTo(4)
        }
        
        // Beat grid
        setupBeatGrid()
        containerView.addSubview(beatGridView)
        beatGridView.snp.makeConstraints { make in
            make.top.equalTo(confidenceBar.snp.bottom).offset(16)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
    }
    
    private func setupBeatGrid() {
        beatGridView.backgroundColor = .clear
        
        // Create beat markers (16 beats for visualization)
        for i in 0..<16 {
            let marker = UIView()
            marker.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
            marker.layer.cornerRadius = 4
            beatGridView.addSubview(marker)
            
            let column = i % 4
            let row = i / 4
            
            marker.snp.makeConstraints { make in
                make.width.height.equalTo(10)
                make.left.equalToSuperview().offset(CGFloat(column) * 30)
                make.top.equalToSuperview().offset(CGFloat(row) * 20)
            }
            
            beatMarkers.append(marker)
        }
        
        // Current beat indicator
        currentBeatView.backgroundColor = StudioTheme.colors.accentPurple
        currentBeatView.layer.cornerRadius = 5
        beatGridView.addSubview(currentBeatView)
        currentBeatView.snp.makeConstraints { make in
            make.width.height.equalTo(10)
            make.left.top.equalToSuperview()
        }
    }
    
    // MARK: - Public API
    
    /// Update beat detection results
    public func updateBeats(
        bpm: Float,
        timeSignature: String,
        beats: [TimeInterval],
        confidence: Float
    ) {
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.beats = beats
        self.confidence = confidence
        
        // Animate update
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.bpmValueLabel.text = String(format: "%.0f", bpm)
            self.timeSignatureValueLabel.text = timeSignature
            self.confidenceBar.progress = confidence
        })
    }
    
    /// Update current beat position
    public func updateCurrentBeat(index: Int) {
        currentBeatIndex = index
        
        guard index < beatMarkers.count else { return }
        
        // Animate current beat indicator
        let marker = beatMarkers[index]
        UIView.animate(withDuration: 0.1) {
            self.currentBeatView.frame = marker.frame
        }
        
        // Highlight current beat
        for (i, beatMarker) in beatMarkers.enumerated() {
            if i == index {
                beatMarker.backgroundColor = StudioTheme.colors.accentPurple
                beatMarker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else {
                beatMarker.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
                beatMarker.transform = CGAffineTransform.identity
            }
        }
    }
    
    /// Clear display
    public func clear() {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.bpmValueLabel.text = "—"
            self.timeSignatureValueLabel.text = "—"
            self.confidenceBar.progress = 0
            
            // Reset beat markers
            for marker in self.beatMarkers {
                marker.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
                marker.transform = CGAffineTransform.identity
            }
        })
    }
}
