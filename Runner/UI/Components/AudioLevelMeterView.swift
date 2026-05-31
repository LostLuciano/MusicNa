import UIKit

/// Real-time audio level meter display
public class AudioLevelMeterView: UIView {
    
    private let barStackView = UIStackView()
    private let dBLabel = UILabel()
    private var bars: [UIView] = []
    private let barCount = 20
    private var currentLevel: Float = -60 {
        didSet {
            updateDisplay()
        }
    }
    
    public var peakLevel: Float = -60
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Background
        backgroundColor = StudioColors.glassDark
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Stack view for bars
        barStackView.axis = .horizontal
        barStackView.distribution = .fillEqually
        barStackView.spacing = 2
        addSubview(barStackView)
        
        barStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            barStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            barStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            barStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            barStackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7)
        ])
        
        // Create bars
        for _ in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = StudioColors.levelSafe
            bar.layer.cornerRadius = 2
            barStackView.addArrangedSubview(bar)
            bars.append(bar)
        }
        
        // dB label
        dBLabel.font = Typography.monospaceMedium
        dBLabel.textColor = StudioColors.textPrimary
        dBLabel.textAlignment = .right
        addSubview(dBLabel)
        
        dBLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dBLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            dBLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    /// Update level meter with current dB value
    public func updateLevel(_ dB: Float) {
        currentLevel = max(-60, min(0, dB))
        peakLevel = max(peakLevel, currentLevel)
    }
    
    private func updateDisplay() {
        // Normalize level to 0-1 range
        let normalized = (currentLevel + 60) / 60
        let activeBarCount = Int(CGFloat(barCount) * CGFloat(normalized))
        
        // Update bars
        for (index, bar) in bars.enumerated() {
            if index < activeBarCount {
                let progress = CGFloat(index) / CGFloat(barCount)
                bar.backgroundColor = StudioColors.levelColor(for: currentLevel)
                bar.alpha = 0.5 + (progress * 0.5)
            } else {
                bar.alpha = 0.2
            }
        }
        
        // Update label
        dBLabel.text = String(format: "%.1f dB", currentLevel)
        dBLabel.textColor = StudioColors.levelColor(for: currentLevel)
    }
    
    /// Reset peak level
    public func resetPeak() {
        peakLevel = currentLevel
    }
}
