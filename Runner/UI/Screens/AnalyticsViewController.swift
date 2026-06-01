import UIKit

/// Analytics/AI Analyzer screen - delegates to AnalyzerViewController
/// Kept for backward compatibility with SceneDelegate tab structure
public class AnalyticsViewController: AnalyzerViewController {
    
    /// Refresh audio analytics when project/playback changes
    public func audioUpdated() {
        // AnalyzerViewController handles this internally
        // This method exists to satisfy SceneDelegate expectations
    }
}
