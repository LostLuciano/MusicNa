import UIKit

/// Floating action button with purple glow
public class FloatingActionButton: UIButton {
    
    private let size: CGFloat = 64
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Size
        widthAnchor.constraint(equalToConstant: size).isActive = true
        heightAnchor.constraint(equalToConstant: size).isActive = true
        
        // Style
        GlassEffect.configurePurpleButton(self, cornerRadius: size / 2)
        
        // Glow
        GlassEffect.addPurpleGlow(to: self, radius: 16)
        
        // Icon
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = StudioColors.purpleAccent
        config.baseForegroundColor = UIColor.white
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 0
        self.configuration = config
    }
    
    /// Set custom icon
    public func setIcon(_ image: UIImage?) {
        var config = configuration ?? UIButton.Configuration.filled()
        config.image = image
        self.configuration = config
    }
    
    /// Add pulse animation
    public func startPulse() {
        GlassEffect.addGlowPulseAnimation(to: self)
    }
    
    /// Stop pulse animation
    public func stopPulse() {
        GlassEffect.removeAnimations(from: self)
    }
}
