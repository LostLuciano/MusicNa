import UIKit

/// Glass morphism effect utilities for liquid glass UI
public struct GlassEffect {
    
    // MARK: - Blur Effect
    
    /// Create a blur effect view with specified style
    public static func createBlurView(style: UIBlurEffect.Style = .dark) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    /// Apply blur effect to a view
    public static func applyBlur(to view: UIView, style: UIBlurEffect.Style = .dark) {
        let blurView = createBlurView(style: style)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 0)
    }
    
    // MARK: - Glass Card Styling
    
    /// Configure a view as a glass card
    public static func configureGlassCard(_ view: UIView, cornerRadius: CGFloat = 24) {
        // Background
        view.backgroundColor = StudioColors.glassLight
        
        // Border
        view.layer.borderColor = StudioColors.glassBorder.cgColor
        view.layer.borderWidth = 1.0
        
        // Corner radius
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        
        // Shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 16
    }
    
    /// Configure a view as a dark glass card
    public static func configureDarkGlassCard(_ view: UIView, cornerRadius: CGFloat = 24) {
        // Background
        view.backgroundColor = StudioColors.glassDark
        
        // Border
        view.layer.borderColor = StudioColors.glassBorder.cgColor
        view.layer.borderWidth = 1.0
        
        // Corner radius
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        
        // Shadow
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize(width: 0, height: 12)
        view.layer.shadowRadius = 20
    }
    
    // MARK: - Glow Effect
    
    /// Add purple glow effect to a view
    public static func addPurpleGlow(to view: UIView, radius: CGFloat = 12) {
        view.layer.shadowColor = StudioColors.purpleGlow.cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = radius
    }
    
    /// Add colored glow effect to a view
    public static func addGlow(to view: UIView, color: UIColor, radius: CGFloat = 12) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = radius
    }
    
    // MARK: - Gradient Background
    
    /// Create a gradient layer for background
    public static func createGradientLayer(frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = [
            StudioColors.backgroundDark.cgColor,
            StudioColors.backgroundMedium.cgColor,
            StudioColors.backgroundDark.cgColor
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        return gradient
    }
    
    /// Apply gradient background to a view
    public static func applyGradientBackground(to view: UIView) {
        let gradient = createGradientLayer(frame: view.bounds)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    // MARK: - Button Styling
    
    /// Configure a button with glass effect
    public static func configureGlassButton(_ button: UIButton, cornerRadius: CGFloat = 12) {
        button.backgroundColor = StudioColors.glassLight
        button.layer.borderColor = StudioColors.glassBorder.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        
        // Set text color
        button.setTitleColor(StudioColors.textPrimary, for: .normal)
        button.setTitleColor(StudioColors.textSecondary, for: .highlighted)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
    }
    
    /// Configure a purple accent button
    public static func configurePurpleButton(_ button: UIButton, cornerRadius: CGFloat = 12) {
        button.backgroundColor = StudioColors.purpleAccent
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
        
        // Set text color
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(StudioColors.textSecondary, for: .highlighted)
        
        // Add glow
        addPurpleGlow(to: button, radius: 12)
    }
    
    // MARK: - Slider Styling
    
    /// Configure a slider with glass effect
    public static func configureGlassSlider(_ slider: UISlider) {
        // Track colors
        slider.minimumTrackTintColor = StudioColors.purpleAccent
        slider.maximumTrackTintColor = StudioColors.textTertiary
        
        // Thumb
        let thumbImage = createThumbImage(size: CGSize(width: 24, height: 24), color: StudioColors.purpleAccent)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)
    }
    
    private static func createThumbImage(size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        color.setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        
        // Add border
        StudioColors.glassBorder.setStroke()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).stroke()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Separator Line
    
    /// Create a glass separator line
    public static func createSeparatorLine() -> UIView {
        let separator = UIView()
        separator.backgroundColor = StudioColors.glassBorder
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    // MARK: - Animation
    
    /// Add pulse animation to a view
    public static func addPulseAnimation(to view: UIView, duration: TimeInterval = 2.0) {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.duration = duration
        pulse.fromValue = 1.0
        pulse.toValue = 0.5
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        view.layer.add(pulse, forKey: "pulse")
    }
    
    /// Add glow pulse animation
    public static func addGlowPulseAnimation(to view: UIView, duration: TimeInterval = 2.0) {
        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.duration = duration
        pulse.fromValue = 0.4
        pulse.toValue = 0.8
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        view.layer.add(pulse, forKey: "glowPulse")
    }
    
    /// Remove all animations from a view
    public static func removeAnimations(from view: UIView) {
        view.layer.removeAllAnimations()
    }
}
