import UIKit

/// ProcessingStageRowView displays a single processing stage with progress indicator.
/// Shows stage name, progress, status, and estimated time.
public class ProcessingStageRowView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let glassBackgroundView = UIView()
    
    // Stage info
    private let stageNameLabel = UILabel()
    private let stageIconLabel = UILabel()
    
    // Progress ring
    private let progressRingView = ProcessingRingView()
    
    // Status
    private let statusLabel = UILabel()
    private let estimatedTimeLabel = UILabel()
    
    // Progress bar (linear)
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    
    // MARK: - Properties
    
    public enum ProcessingStatus {
        case pending
        case processing
        case complete
        case error
        
        var displayText: String {
            switch self {
            case .pending:
                return "Pending"
            case .processing:
                return "Processing..."
            case .complete:
                return "Complete"
            case .error:
                return "Error"
            }
        }
        
        var displayColor: UIColor {
            switch self {
            case .pending:
                return StudioTheme.colors.textSecondary
            case .processing:
                return StudioTheme.colors.accentPurple
            case .complete:
                return UIColor.systemGreen
            case .error:
                return UIColor.systemRed
            }
        }
    }
    
    private var stageName: String = "Processing"
    private var stageIcon: String = "⚙️"
    private var status: ProcessingStatus = .pending
    private var progress: Float = 0
    private var estimatedTime: TimeInterval = 0
    
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
        glassBackgroundView.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.05)
        glassBackgroundView.layer.cornerRadius = 12
        glassBackgroundView.layer.borderWidth = 1
        glassBackgroundView.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.1).cgColor
        
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
            make.edges.equalToSuperview().inset(12)
        }
        
        // Stage icon
        stageIconLabel.font = UIFont.systemFont(ofSize: 20)
        stageIconLabel.text = "⚙️"
        containerView.addSubview(stageIconLabel)
        stageIconLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(28)
        }
        
        // Stage name
        stageNameLabel.text = "Processing"
        stageNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stageNameLabel.textColor = StudioTheme.colors.textPrimary
        containerView.addSubview(stageNameLabel)
        stageNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(stageIconLabel.snp.right).offset(8)
            make.right.equalToSuperview()
        }
        
        // Progress ring
        progressRingView.layer.cornerRadius = 20
        containerView.addSubview(progressRingView)
        progressRingView.snp.makeConstraints { make in
            make.top.equalTo(stageNameLabel.snp.bottom).offset(8)
            make.left.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Status label
        statusLabel.text = "Pending"
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = StudioTheme.colors.textSecondary
        containerView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(stageNameLabel.snp.bottom).offset(8)
            make.left.equalTo(progressRingView.snp.right).offset(12)
        }
        
        // Estimated time label
        estimatedTimeLabel.text = "—"
        estimatedTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        estimatedTimeLabel.textColor = StudioTheme.colors.textSecondary
        estimatedTimeLabel.textAlignment = .right
        containerView.addSubview(estimatedTimeLabel)
        estimatedTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(stageNameLabel.snp.bottom).offset(8)
            make.right.equalToSuperview()
            make.left.equalTo(statusLabel.snp.right).offset(8)
        }
        
        // Progress bar
        progressBar.progressTintColor = StudioTheme.colors.accentPurple
        progressBar.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        containerView.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(progressRingView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(4)
        }
    }
    
    // MARK: - Public API
    
    /// Configure processing stage
    public func configure(
        name: String,
        icon: String,
        status: ProcessingStatus = .pending
    ) {
        stageName = name
        stageIcon = icon
        self.status = status
        
        stageNameLabel.text = name
        stageIconLabel.text = icon
        statusLabel.text = status.displayText
        statusLabel.textColor = status.displayColor
        
        updateVisualState()
    }
    
    /// Update progress
    public func updateProgress(_ progress: Float, estimatedTime: TimeInterval = 0) {
        self.progress = progress
        self.estimatedTime = estimatedTime
        
        // Update progress bar
        progressBar.progress = progress
        
        // Update progress ring
        progressRingView.setProgress(progress)
        
        // Update estimated time
        if estimatedTime > 0 {
            estimatedTimeLabel.text = formatTime(estimatedTime)
        } else {
            estimatedTimeLabel.text = "—"
        }
    }
    
    /// Update status
    public func updateStatus(_ status: ProcessingStatus) {
        self.status = status
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.statusLabel.text = status.displayText
            self.statusLabel.textColor = status.displayColor
        })
        
        updateVisualState()
    }
    
    /// Mark as complete
    public func markComplete() {
        updateStatus(.complete)
        progressBar.progress = 1.0
        progressRingView.setProgress(1.0)
    }
    
    /// Mark as error
    public func markError() {
        updateStatus(.error)
    }
    
    // MARK: - Private Methods
    
    private func updateVisualState() {
        // Update border color based on status
        let borderColor: UIColor
        switch status {
        case .pending:
            borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.1)
        case .processing:
            borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.3)
        case .complete:
            borderColor = UIColor.systemGreen.withAlphaComponent(0.3)
        case .error:
            borderColor = UIColor.systemRed.withAlphaComponent(0.3)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.glassBackgroundView.layer.borderColor = borderColor.cgColor
        }
        
        // Animate if processing
        if status == .processing {
            startProcessingAnimation()
        } else {
            stopProcessingAnimation()
        }
    }
    
    private func startProcessingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 2.0
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        stageIconLabel.layer.add(rotation, forKey: "rotation")
    }
    
    private func stopProcessingAnimation() {
        stageIconLabel.layer.removeAnimation(forKey: "rotation")
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%dm %ds", minutes, secs)
        }
    }
}
