import UIKit

/// StemChannelView displays a single stem channel with volume control, mute, solo, and level meter.
/// Used in MixerViewController for real-time stem mixing.
public class StemChannelView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let glassBackgroundView = UIView()
    
    // Stem info
    private let stemNameLabel = UILabel()
    private let stemIconLabel = UILabel()
    
    // Level meter
    private let levelMeterView = AudioLevelMeterView()
    
    // Volume control
    private let volumeSlider = UISlider()
    private let volumeLabel = UILabel()
    
    // Control buttons
    private let muteButton = UIButton(type: .system)
    private let soloButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private var stemName: String = "Vocals"
    private var stemIcon: String = "🎤"
    private var currentVolume: Float = 1.0
    private var isMuted: Bool = false
    private var isSolo: Bool = false
    
    public var onVolumeChanged: ((Float) -> Void)?
    public var onMuteToggled: ((Bool) -> Void)?
    public var onSoloToggled: ((Bool) -> Void)?
    
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
        glassBackgroundView.layer.cornerRadius = 12
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
            make.edges.equalToSuperview().inset(12)
        }
        
        // Stem icon
        stemIconLabel.font = UIFont.systemFont(ofSize: 24)
        stemIconLabel.text = "🎤"
        containerView.addSubview(stemIconLabel)
        stemIconLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        // Stem name
        stemNameLabel.text = "Vocals"
        stemNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stemNameLabel.textColor = StudioTheme.colors.textPrimary
        containerView.addSubview(stemNameLabel)
        stemNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(stemIconLabel.snp.right).offset(8)
            make.right.equalToSuperview()
        }
        
        // Level meter
        levelMeterView.layer.cornerRadius = 4
        containerView.addSubview(levelMeterView)
        levelMeterView.snp.makeConstraints { make in
            make.top.equalTo(stemNameLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
        }
        
        // Volume slider
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1.0
        volumeSlider.value = 1.0
        volumeSlider.minimumTrackTintColor = StudioTheme.colors.accentPurple
        volumeSlider.maximumTrackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        containerView.addSubview(volumeSlider)
        volumeSlider.snp.makeConstraints { make in
            make.top.equalTo(levelMeterView.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
        }
        
        // Volume label
        volumeLabel.text = "100%"
        volumeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        volumeLabel.textColor = StudioTheme.colors.textSecondary
        volumeLabel.textAlignment = .center
        containerView.addSubview(volumeLabel)
        volumeLabel.snp.makeConstraints { make in
            make.top.equalTo(volumeSlider.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        // Mute button
        muteButton.setTitle("🔊 Mute", for: .normal)
        muteButton.setTitle("🔇 Muted", for: .selected)
        muteButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        muteButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        muteButton.setTitleColor(StudioTheme.colors.accentPurple, for: .selected)
        muteButton.addTarget(self, action: #selector(muteToggled), for: .touchUpInside)
        containerView.addSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.top.equalTo(volumeLabel.snp.bottom).offset(8)
            make.left.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(32)
        }
        
        // Solo button
        soloButton.setTitle("🎯 Solo", for: .normal)
        soloButton.setTitle("🎯 Solo", for: .selected)
        soloButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        soloButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        soloButton.setTitleColor(StudioTheme.colors.accentPurple, for: .selected)
        soloButton.addTarget(self, action: #selector(soloToggled), for: .touchUpInside)
        containerView.addSubview(soloButton)
        soloButton.snp.makeConstraints { make in
            make.top.equalTo(volumeLabel.snp.bottom).offset(8)
            make.right.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
            make.height.equalTo(32)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public API
    
    /// Configure stem channel
    public func configure(
        name: String,
        icon: String,
        volume: Float = 1.0,
        isMuted: Bool = false,
        isSolo: Bool = false
    ) {
        stemName = name
        stemIcon = icon
        currentVolume = volume
        self.isMuted = isMuted
        self.isSolo = isSolo
        
        stemNameLabel.text = name
        stemIconLabel.text = icon
        volumeSlider.value = volume
        volumeLabel.text = String(format: "%.0f%%", volume * 100)
        
        muteButton.isSelected = isMuted
        soloButton.isSelected = isSolo
        
        // Update visual state
        updateVisualState()
    }
    
    /// Update level meter
    public func updateLevel(_ level: Float) {
        levelMeterView.updateLevel(level)
    }
    
    /// Set volume
    public func setVolume(_ volume: Float) {
        currentVolume = volume
        volumeSlider.value = volume
        volumeLabel.text = String(format: "%.0f%%", volume * 100)
    }
    
    /// Toggle mute
    public func toggleMute() {
        isMuted.toggle()
        muteButton.isSelected = isMuted
        updateVisualState()
        onMuteToggled?(isMuted)
    }
    
    /// Toggle solo
    public func toggleSolo() {
        isSolo.toggle()
        soloButton.isSelected = isSolo
        updateVisualState()
        onSoloToggled?(isSolo)
    }
    
    // MARK: - Private Methods
    
    @objc private func volumeChanged() {
        currentVolume = volumeSlider.value
        volumeLabel.text = String(format: "%.0f%%", currentVolume * 100)
        onVolumeChanged?(currentVolume)
    }
    
    @objc private func muteToggled() {
        toggleMute()
    }
    
    @objc private func soloToggled() {
        toggleSolo()
    }
    
    private func updateVisualState() {
        // Adjust opacity based on mute state
        let alpha: CGFloat = isMuted ? 0.5 : 1.0
        UIView.animate(withDuration: 0.2) {
            self.levelMeterView.alpha = alpha
            self.volumeSlider.alpha = alpha
        }
        
        // Highlight if solo is active
        if isSolo {
            glassBackgroundView.layer.borderColor = StudioTheme.colors.accentPurple.cgColor
            glassBackgroundView.layer.borderWidth = 2
        } else {
            glassBackgroundView.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2).cgColor
            glassBackgroundView.layer.borderWidth = 1
        }
    }
}
