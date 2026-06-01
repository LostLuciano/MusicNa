import UIKit

/// Central theme coordinator for Studio UI
public class StudioTheme {
    
    static let shared = StudioTheme()
    
    // MARK: - Static Color & Typography Access (for StudioTheme.colors.xxx syntax)
    public static let colors = StudioColors.self
    public static let typography = Typography.self
    
    // MARK: - Spacing
    
    public let spacing2: CGFloat = 2
    public let spacing4: CGFloat = 4
    public let spacing8: CGFloat = 8
    public let spacing12: CGFloat = 12
    public let spacing16: CGFloat = 16
    public let spacing20: CGFloat = 20
    public let spacing24: CGFloat = 24
    public let spacing32: CGFloat = 32
    public let spacing40: CGFloat = 40
    public let spacing48: CGFloat = 48
    
    // MARK: - Corner Radius
    
    public let cornerSmall: CGFloat = 8
    public let cornerMedium: CGFloat = 12
    public let cornerLarge: CGFloat = 24
    public let cornerXL: CGFloat = 32
    
    // MARK: - Shadow
    
    public let shadowSmall = (offset: CGSize(width: 0, height: 2), radius: CGFloat(4), opacity: Float(0.1))
    public let shadowMedium = (offset: CGSize(width: 0, height: 4), radius: CGFloat(8), opacity: Float(0.2))
    public let shadowLarge = (offset: CGSize(width: 0, height: 8), radius: CGFloat(16), opacity: Float(0.3))
    
    // MARK: - Animation Duration
    
    public let animationFast: TimeInterval = 0.2
    public let animationNormal: TimeInterval = 0.3
    public let animationSlow: TimeInterval = 0.5
    
    // MARK: - Setup
    
    public func setupAppearance() {
        // Navigation bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = StudioColors.backgroundDark
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: StudioColors.textPrimary,
            .font: Typography.heading2
        ]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = StudioColors.backgroundDark.withAlphaComponent(0.8)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Segmented control
        let segmentedAppearance = UISegmentedControl.appearance()
        segmentedAppearance.setTitleTextAttributes(
            [.font: Typography.labelMedium, .foregroundColor: StudioColors.textPrimary],
            for: .normal
        )
        segmentedAppearance.setTitleTextAttributes(
            [.font: Typography.labelMedium, .foregroundColor: UIColor.white],
            for: .selected
        )
    }
    
    // MARK: - View Configuration Helpers
    
    public func configureViewController(_ vc: UIViewController) {
        vc.view.backgroundColor = StudioColors.backgroundDark
        GlassEffect.applyGradientBackground(to: vc.view)
    }
    
    public func configureGlassCard(_ view: UIView) {
        GlassEffect.configureGlassCard(view, cornerRadius: cornerLarge)
    }
    
    public func configureDarkGlassCard(_ view: UIView) {
        GlassEffect.configureDarkGlassCard(view, cornerRadius: cornerLarge)
    }
    
    public func configureButton(_ button: UIButton, style: ButtonStyle = .glass) {
        switch style {
        case .glass:
            GlassEffect.configureGlassButton(button, cornerRadius: cornerMedium)
        case .purple:
            GlassEffect.configurePurpleButton(button, cornerRadius: cornerMedium)
        }
    }
    
    public enum ButtonStyle {
        case glass
        case purple
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    
    func setupStudioTheme() {
        StudioTheme.shared.configureViewController(self)
    }
    
    func setupNavigationBar(title: String, subtitle: String? = nil) {
        self.title = title
        
        if let subtitle = subtitle {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = Typography.heading2
            titleLabel.textColor = StudioColors.textPrimary
            
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = Typography.bodySmall
            subtitleLabel.textColor = StudioColors.textSecondary
            
            let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            stackView.axis = .vertical
            stackView.alignment = .leading
            stackView.spacing = 2
            
            self.navigationItem.titleView = stackView
        }
    }
}

// MARK: - UIView Extension

extension UIView {
    
    func setupGlassCard() {
        StudioTheme.shared.configureGlassCard(self)
    }
    
    func setupDarkGlassCard() {
        StudioTheme.shared.configureDarkGlassCard(self)
    }
    
    func addPurpleGlow() {
        GlassEffect.addPurpleGlow(to: self)
    }
    
    func addGlow(color: UIColor) {
        GlassEffect.addGlow(to: self, color: color)
    }
}

// MARK: - UIButton Extension

extension UIButton {
    
    func setupGlassStyle() {
        StudioTheme.shared.configureButton(self, style: .glass)
    }
    
    func setupPurpleStyle() {
        StudioTheme.shared.configureButton(self, style: .purple)
    }
}
