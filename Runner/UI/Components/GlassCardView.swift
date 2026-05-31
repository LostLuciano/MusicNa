import UIKit

/// Reusable glass card component with optional blur effect
public class GlassCardView: UIView {
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let contentView = UIView()
    
    public var cornerRadius: CGFloat = 24 {
        didSet {
            updateCornerRadius()
        }
    }
    
    public var isDark: Bool = false {
        didSet {
            updateStyle()
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
        // Blur view
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        
        // Content view
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        // Styling
        updateStyle()
        updateCornerRadius()
    }
    
    private func updateStyle() {
        if isDark {
            GlassEffect.configureDarkGlassCard(self, cornerRadius: cornerRadius)
        } else {
            GlassEffect.configureGlassCard(self, cornerRadius: cornerRadius)
        }
    }
    
    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
        blurView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerRadius = cornerRadius
    }
    
    /// Add a subview to the content area
    public func addContentView(_ view: UIView) {
        contentView.addSubview(view)
    }
    
    /// Get the content view for adding constraints
    public func getContentView() -> UIView {
        return contentView
    }
    
    /// Add purple glow effect
    public func addGlow() {
        GlassEffect.addPurpleGlow(to: self)
    }
    
    /// Add custom color glow
    public func addGlow(color: UIColor) {
        GlassEffect.addGlow(to: self, color: color)
    }
}

// MARK: - Convenience Initializer

extension GlassCardView {
    
    /// Create a glass card with specified configuration
    public static func create(
        isDark: Bool = false,
        cornerRadius: CGFloat = 24,
        withGlow: Bool = false,
        glowColor: UIColor? = nil
    ) -> GlassCardView {
        let card = GlassCardView()
        card.isDark = isDark
        card.cornerRadius = cornerRadius
        
        if withGlow {
            if let glowColor = glowColor {
                card.addGlow(color: glowColor)
            } else {
                card.addGlow()
            }
        }
        
        return card
    }
}
