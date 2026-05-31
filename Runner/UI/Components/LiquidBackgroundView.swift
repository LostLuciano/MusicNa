import UIKit

/// Animated liquid gradient background for screens
public class LiquidBackgroundView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private var animationTimer: Timer?
    
    public var isAnimated: Bool = true {
        didSet {
            if isAnimated {
                startAnimation()
            } else {
                stopAnimation()
            }
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
        // Gradient layer
        gradientLayer.colors = [
            StudioColors.backgroundDark.cgColor,
            StudioColors.backgroundMedium.cgColor,
            StudioColors.backgroundDark.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    /// Start gradient animation
    public func startAnimation() {
        guard animationTimer == nil else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.animateGradient()
        }
    }
    
    /// Stop gradient animation
    public func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.duration = 3.0
        animation.fromValue = [0, 0.5, 1]
        animation.toValue = [0.2, 0.7, 1.2]
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = 1
        
        gradientLayer.add(animation, forKey: "gradientAnimation")
    }
    
    deinit {
        stopAnimation()
    }
}
