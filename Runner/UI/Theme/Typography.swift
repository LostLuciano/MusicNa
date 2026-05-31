import UIKit

/// Studio typography system
public struct Typography {
    
    // MARK: - Display Fonts (Large titles)
    
    /// Extra large display font (48pt, bold)
    public static let displayXL: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 48, weight: .bold)
        } else {
            return UIFont.boldSystemFont(ofSize: 48)
        }
    }()
    
    /// Large display font (40pt, bold)
    public static let displayLarge: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 40, weight: .bold)
        } else {
            return UIFont.boldSystemFont(ofSize: 40)
        }
    }()
    
    /// Medium display font (32pt, bold)
    public static let displayMedium: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 32, weight: .bold)
        } else {
            return UIFont.boldSystemFont(ofSize: 32)
        }
    }()
    
    // MARK: - Heading Fonts
    
    /// Heading 1 (28pt, semibold)
    public static let heading1: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 28, weight: .semibold)
        } else {
            return UIFont.boldSystemFont(ofSize: 28)
        }
    }()
    
    /// Heading 2 (24pt, semibold)
    public static let heading2: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 24, weight: .semibold)
        } else {
            return UIFont.boldSystemFont(ofSize: 24)
        }
    }()
    
    /// Heading 3 (20pt, semibold)
    public static let heading3: UIFont = {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: 20, weight: .semibold)
        } else {
            return UIFont.boldSystemFont(ofSize: 20)
        }
    }()
    
    // MARK: - Body Fonts
    
    /// Body large (18pt, regular)
    public static let bodyLarge: UIFont = {
        UIFont.systemFont(ofSize: 18, weight: .regular)
    }()
    
    /// Body medium (16pt, regular)
    public static let bodyMedium: UIFont = {
        UIFont.systemFont(ofSize: 16, weight: .regular)
    }()
    
    /// Body small (14pt, regular)
    public static let bodySmall: UIFont = {
        UIFont.systemFont(ofSize: 14, weight: .regular)
    }()
    
    // MARK: - Label Fonts
    
    /// Label large (16pt, medium)
    public static let labelLarge: UIFont = {
        UIFont.systemFont(ofSize: 16, weight: .medium)
    }()
    
    /// Label medium (14pt, medium)
    public static let labelMedium: UIFont = {
        UIFont.systemFont(ofSize: 14, weight: .medium)
    }()
    
    /// Label small (12pt, medium)
    public static let labelSmall: UIFont = {
        UIFont.systemFont(ofSize: 12, weight: .medium)
    }()
    
    // MARK: - Caption Fonts
    
    /// Caption large (12pt, regular)
    public static let captionLarge: UIFont = {
        UIFont.systemFont(ofSize: 12, weight: .regular)
    }()
    
    /// Caption small (10pt, regular)
    public static let captionSmall: UIFont = {
        UIFont.systemFont(ofSize: 10, weight: .regular)
    }()
    
    // MARK: - Monospace Fonts (for timers, values)
    
    /// Monospace large (18pt)
    public static let monospaceLarge: UIFont = {
        if #available(iOS 13.0, *) {
            return UIFont.monospacedSystemFont(ofSize: 18, weight: .regular)
        } else {
            return UIFont.systemFont(ofSize: 18, weight: .regular)
        }
    }()
    
    /// Monospace medium (16pt)
    public static let monospaceMedium: UIFont = {
        if #available(iOS 13.0, *) {
            return UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        } else {
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        }
    }()
    
    /// Monospace small (14pt)
    public static let monospaceSmall: UIFont = {
        if #available(iOS 13.0, *) {
            return UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        } else {
            return UIFont.systemFont(ofSize: 14, weight: .regular)
        }
    }()
}

// MARK: - UILabel Extensions

extension UILabel {
    
    func setDisplayXL(_ text: String) {
        self.font = Typography.displayXL
        self.text = text
    }
    
    func setHeading1(_ text: String) {
        self.font = Typography.heading1
        self.text = text
    }
    
    func setHeading2(_ text: String) {
        self.font = Typography.heading2
        self.text = text
    }
    
    func setHeading3(_ text: String) {
        self.font = Typography.heading3
        self.text = text
    }
    
    func setBodyLarge(_ text: String) {
        self.font = Typography.bodyLarge
        self.text = text
    }
    
    func setBodyMedium(_ text: String) {
        self.font = Typography.bodyMedium
        self.text = text
    }
    
    func setBodySmall(_ text: String) {
        self.font = Typography.bodySmall
        self.text = text
    }
    
    func setLabelLarge(_ text: String) {
        self.font = Typography.labelLarge
        self.text = text
    }
    
    func setLabelMedium(_ text: String) {
        self.font = Typography.labelMedium
        self.text = text
    }
    
    func setLabelSmall(_ text: String) {
        self.font = Typography.labelSmall
        self.text = text
    }
    
    func setCaptionLarge(_ text: String) {
        self.font = Typography.captionLarge
        self.text = text
    }
    
    func setCaptionSmall(_ text: String) {
        self.font = Typography.captionSmall
        self.text = text
    }
}
