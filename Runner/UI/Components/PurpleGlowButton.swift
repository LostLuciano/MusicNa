import UIKit

/// Button with purple glow effect
public class PurpleGlowButton: UIButton {
    
    public var glowColor: UIColor = StudioColors.purpleAccent {
        didSet {
            updateGlow()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        GlassEffect.configurePurpleButton(self, cornerRadius: 12)
        updateGlow()
    }
    
    private func updateGlow() {
        GlassEffect.addGlow(to: self, color: glowColor, radius: 12)
    }
    
    /// Set button title and style
    public func setTitle(_ title: String, font: UIFont = Typography.labelLarge) {
        setTitle(title, for: .normal)
        titleLabel?.font = font
    }
    
    /// Add pulse animation
    public func startPulse() {
        GlassEffect.addGlowPulseAnimation(to: self, duration: 2.0)
    }
    
    /// Stop pulse animation
    public func stopPulse() {
        GlassEffect.removeAnimations(from: self)
    }
}
