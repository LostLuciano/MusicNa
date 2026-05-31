import UIKit

/// Studio color palette for liquid glass purple theme
public struct StudioColors {
    
    // MARK: - Primary Colors
    
    /// Deep purple/black gradient background
    public static let backgroundDark = UIColor(red: 0.08, green: 0.06, blue: 0.15, alpha: 1.0)
    
    /// Slightly lighter purple for secondary backgrounds
    public static let backgroundMedium = UIColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1.0)
    
    /// Purple accent color
    public static let purpleAccent = UIColor(red: 0.70, green: 0.40, blue: 1.0, alpha: 1.0)
    
    /// Bright purple for highlights and glows
    public static let purpleGlow = UIColor(red: 0.80, green: 0.50, blue: 1.0, alpha: 1.0)
    
    // MARK: - Glass Effect Colors
    
    /// Glass card background (semi-transparent)
    public static let glassLight = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
    
    /// Glass card background (darker)
    public static let glassDark = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.20)
    
    /// Glass border color
    public static let glassBorder = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15)
    
    // MARK: - Text Colors
    
    /// Primary text (white)
    public static let textPrimary = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    /// Secondary text (light gray)
    public static let textSecondary = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.7)
    
    /// Tertiary text (dimmer gray)
    public static let textTertiary = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.5)
    
    // MARK: - Status Colors
    
    /// Success/ready state (green)
    public static let statusSuccess = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
    
    /// Warning state (yellow/orange)
    public static let statusWarning = UIColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
    
    /// Error/failed state (red)
    public static let statusError = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
    
    /// Processing state (cyan)
    public static let statusProcessing = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
    
    // MARK: - Audio Level Colors
    
    /// Safe audio level (green)
    public static let levelSafe = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
    
    /// Caution audio level (yellow)
    public static let levelCaution = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
    
    /// Clipping audio level (red)
    public static let levelClipping = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
    
    // MARK: - Stem Colors
    
    /// Vocals stem color
    public static let stemVocals = UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
    
    /// Drums stem color
    public static let stemDrums = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    
    /// Bass stem color
    public static let stemBass = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
    
    /// Guitar stem color
    public static let stemGuitar = UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
    
    /// Piano stem color
    public static let stemPiano = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
    
    /// Other stem color
    public static let stemOther = UIColor(red: 0.8, green: 0.4, blue: 0.8, alpha: 1.0)
    
    // MARK: - Utility
    
    public static func stemColor(for stemName: String) -> UIColor {
        switch stemName.lowercased() {
        case "vocals":
            return stemVocals
        case "drums":
            return stemDrums
        case "bass":
            return stemBass
        case "guitar":
            return stemGuitar
        case "piano":
            return stemPiano
        default:
            return stemOther
        }
    }
    
    public static func statusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "ready", "separated", "analyzed":
            return statusSuccess
        case "processing", "separating", "analyzing":
            return statusProcessing
        case "failed", "error":
            return statusError
        case "pending":
            return statusWarning
        default:
            return textSecondary
        }
    }
    
    public static func levelColor(for dB: Float) -> UIColor {
        if dB > -3 {
            return levelClipping
        } else if dB > -12 {
            return levelCaution
        } else {
            return levelSafe
        }
    }
}
