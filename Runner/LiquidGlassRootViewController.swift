import UIKit

/// Root view controller with Liquid Glass design for iOS 18+
/// Replaces old Music Stem Studio dashboard with modern glass UI
class LiquidGlassRootViewController: UITabBarController {
    
    // Shared audio/ML models
    let separator = CoreMLStemSeparator()
    let audioEngine = AudioEngineManager()
    let chordDetector = ChordDetectionManager()
    let beatDetector = BeatDetectionManager()
    let metronome = MetronomeManager()
    let lyricsManager = LyricsManager()
    
    // State
    var currentSongURL: URL?
    var separatedStems: [String: URL] = [:]
    var chordSegments: [ChordSegment] = []
    var beatResult: BeatTempoResult?
    var hasActiveSeparation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGlassTabBar()
        setupViewControllers()
    }
    
    private func setupGlassTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        appearance.stackedLayoutAppearance.selected.iconColor = .systemCyan
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemCyan,
            .font: UIFont.boldSystemFont(ofSize: 11)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 11)
        ]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemCyan
        tabBar.unselectedItemTintColor = .lightGray
    }
    
    private func setupViewControllers() {
        let dashboardVC = LiquidGlassDashboardViewController()
        let mixerVC = LiquidGlassMixerViewController()
        let analyticsVC = LiquidGlassAnalyticsViewController()
        
        dashboardVC.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "music.note.house"),
            selectedImage: UIImage(systemName: "music.note.house.fill")
        )
        
        mixerVC.tabBarItem = UITabBarItem(
            title: "Mixer",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )
        
        analyticsVC.tabBarItem = UITabBarItem(
            title: "Analyzer",
            image: UIImage(systemName: "waveform.and.mic"),
            selectedImage: UIImage(systemName: "waveform.and.mic")
        )
        
        let vcs = [dashboardVC, mixerVC, analyticsVC].map { vc -> UINavigationController in
            let nav = UINavigationController(rootViewController: vc)
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithDefaultBackground()
            navAppearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.9)
            navAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 18)
            ]
            nav.navigationBar.standardAppearance = navAppearance
            nav.navigationBar.scrollEdgeAppearance = navAppearance
            return nav
        }
        
        self.viewControllers = vcs
    }
    
    func updateAudioFile(url: URL, stems: [String: URL]?, chords: [ChordSegment], beats: BeatTempoResult?) {
        self.currentSongURL = url
        if let stems = stems { self.separatedStems = stems }
        self.chordSegments = chords
        self.beatResult = beats
    }
}

// MARK: - Dashboard
class LiquidGlassDashboardViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dashboard"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
    }
    func audioUpdated() {}
}

// MARK: - Mixer
class LiquidGlassMixerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mixer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
    }
    func audioUpdated() {}
}

// MARK: - Analytics
class LiquidGlassAnalyticsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Analyzer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
    }
    func audioUpdated() {}
}
