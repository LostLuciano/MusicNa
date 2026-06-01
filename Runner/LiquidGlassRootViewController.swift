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
        // Modern glass tab bar appearance for iOS 18+
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Glass background with blur
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        // Active item: Cyan/Electric Blue (Liquid Glass accent)
        appearance.stackedLayoutAppearance.selected.iconColor = .systemCyan
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemCyan,
            .font: UIFont.boldSystemFont(ofSize: 11)
        ]
        
        // Inactive item: Subtle gray
        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 11)
        ]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemCyan
        tabBar.unselectedItemTintColor = .lightGray
        
        // Add subtle glass border on top
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5))
        topBorder.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.2)
        topBorder.autoresizingMask = [.flexibleWidth]
        tabBar.addSubview(topBorder)
    }
    
    private func setupViewControllers() {
        let dashboardVC = LiquidGlassDashboardViewController()
        let mixerVC = LiquidGlassMixerViewController()
        let analyticsVC = LiquidGlassAnalyticsViewController()
        
        // Tab bar items with SF Symbols
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
        
        // Embed in navigation controllers with glass navbar
        let vcs = [dashboardVC, mixerVC, analyticsVC].map { vc -> UINavigationController in
            let nav = UINavigationController(rootViewController: vc)
            
            // Glass navbar appearance
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
            nav.navigationBar.prefersLargeTitles = false
            
            return nav
        }
        
        self.viewControllers = vcs
    }
    
    // Notify all screens about audio updates
    func updateAudioFile(url: URL, stems: [String: URL]?, chords: [ChordSegment], beats: BeatTempoResult?) {
        self.currentSongURL = url
        if let stems = stems {
            self.separatedStems = stems
        }
        self.chordSegments = chords
        self.beatResult = beats
        
        if let viewControllers = self.viewControllers {
            for vc in viewControllers {
                if let nav = vc as? UINavigationController {
                    if let dashboard = nav.viewControllers.first as? LiquidGlassDashboardViewController {
                        dashboard.audioUpdated()
                    }
                    if let mixer = nav.viewControllers.first as? LiquidGlassMixerViewController {
                        mixer.audioUpdated()
                    }
                    if let analytics = nav.viewControllers.first as? LiquidGlassAnalyticsViewController {
                        analytics.audioUpdated()
                    }
                }
            }
        }
    }
}

// MARK: - Liquid Glass Dashboard
class LiquidGlassDashboardViewController: UIViewController, UIDocumentPickerDelegate {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerLabel = UILabel()
    private let versionLabel = UILabel()
    
    // Track selection card (glass)
    private let trackCard = UIView()
    private let trackTitle = UILabel()
    private let trackSegmentedControl = UISegmentedControl()
    private let importButton = UIButton(type: .system)
    
    // Config card (glass)
    private let configCard = UIView()
    private let configTitle = UILabel()
    private let qualityLabel = UILabel()
    private let qualitySegmentedControl = UISegmentedControl(items: ["Light (FP16)", "Standard (FP32)"])
    private let computeLabel = UILabel()
    private let computeSegmentedControl = UISegmentedControl(items: ["All (ANE)", "GPU", "CPU"])
    
    // Action card (glass)
    private let actionCard = UIView()
    private let actionButton = UIButton(type: .custom)
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    
    private let songs = [
        ("classical", "Classical"),
        ("trap", "Trap"),
        ("edm", "EDM"),
        ("dubstep", "Dubstep"),
        ("country", "Country"),
        ("drumNBass", "Drum & Bass"),
        ("folkRock", "Folk Rock"),
        ("latino", "Latino"),
        ("metal", "Metal"),
        ("reggaeton", "Reggaeton"),
        ("rnb", "RnB")
    ]
    
    private var selectedSongName: String = "classical"
    private var customImportedURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dashboard"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
        
        setupLayout()
        setupStyles()
        selectSong(index: 0)
    }
    
    /// Selects song by index safely - fallback when no songs available
    private func selectSong(index: Int) {
        // Placeholder: ensures UI does not crash if no songs loaded
        // Will be connected to real project/song data later
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Header
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)
        contentView.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            versionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            versionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Track card
        trackCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trackCard)
        
        trackTitle.translatesAutoresizingMaskIntoConstraints = false
        trackSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        importButton.translatesAutoresizingMaskIntoConstraints = false
        trackCard.addSubview(trackTitle)
        trackCard.addSubview(trackSegmentedControl)
        trackCard.addSubview(importButton)
        
        NSLayoutConstraint.activate([
            trackCard.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 20),
            trackCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            trackCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            trackTitle.topAnchor.constraint(equalTo: trackCard.topAnchor, constant: 16),
            trackTitle.leadingAnchor.constraint(equalTo: trackCard.leadingAnchor, constant: 16),
            trackTitle.trailingAnchor.constraint(equalTo: trackCard.trailingAnchor, constant: -16),
            
            trackSegmentedControl.topAnchor.constraint(equalTo: trackTitle.bottomAnchor, constant: 12),
            trackSegmentedControl.leadingAnchor.constraint(equalTo: trackCard.leadingAnchor, constant: 16),
            trackSegmentedControl.trailingAnchor.constraint(equalTo: trackCard.trailingAnchor, constant: -16),
            trackSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            importButton.topAnchor.constraint(equalTo: trackSegmentedControl.bottomAnchor, constant: 12),
            importButton.leadingAnchor.constraint(equalTo: trackCard.leadingAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: trackCard.trailingAnchor, constant: -16),
            importButton.bottomAnchor.constraint(equalTo: trackCard.bottomAnchor, constant: -16),
            importButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Config card
        configCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(configCard)
        
        configTitle.translatesAutoresizingMaskIntoConstraints = false
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        qualitySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        computeLabel.translatesAutoresizingMaskIntoConstraints = false
        computeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        configCard.addSubview(configTitle)
        configCard.addSubview(qualityLabel)
        configCard.addSubview(qualitySegmentedControl)
        configCard.addSubview(computeLabel)
        configCard.addSubview(computeSegmentedControl)
        
        NSLayoutConstraint.activate([
            configCard.topAnchor.constraint(equalTo: trackCard.bottomAnchor, constant: 20),
            configCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            configCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            configTitle.topAnchor.constraint(equalTo: configCard.topAnchor, constant: 16),
            configTitle.leadingAnchor.constraint(equalTo: configCard.leadingAnchor, constant: 16),
            configTitle.trailingAnchor.constraint(equalTo: configCard.trailingAnchor, constant: -16),
            
            qualityLabel.topAnchor.constraint(equalTo: configTitle.bottomAnchor, constant: 12),
            qualityLabel.leadingAnchor.constraint(equalTo: configCard.leadingAnchor, constant: 16),
            
            qualitySegmentedControl.topAnchor.constraint(equalTo: qualityLabel.bottomAnchor, constant: 6),
            qualitySegmentedControl.leadingAnchor.constraint(equalTo: configCard.leadingAnchor, constant: 16),
            qualitySegmentedControl.trailingAnchor.constraint(equalTo: configCard.trailingAnchor, constant: -16),
            qualitySegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            computeLabel.topAnchor.constraint(equalTo: qualitySegmentedControl.bottomAnchor, constant: 12),
            computeLabel.leadingAnchor.constraint(equalTo: configCard.leadingAnchor, constant: 16),
            
            computeSegmentedControl.topAnchor.constraint(equalTo: computeLabel.bottomAnchor, constant: 6),
            computeSegmentedControl.leadingAnchor.constraint(equalTo: configCard.leadingAnchor, constant: 16),
            computeSegmentedControl.trailingAnchor.constraint(equalTo: configCard.trailingAnchor, constant: -16),
            computeSegmentedControl.bottomAnchor.constraint(equalTo: configCard.bottomAnchor, constant: -16),
            computeSegmentedControl.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Action card
        actionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionCard)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        actionCard.addSubview(actionButton)
        actionCard.addSubview(statusLabel)
        actionCard.addSubview(spinner)
        
        NSLayoutConstraint.activate([
            actionCard.topAnchor.constraint(equalTo: configCard.bottomAnchor, constant: 20),
            actionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            actionButton.topAnchor.constraint(equalTo: actionCard.topAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: actionCard.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 120),
            
            spinner.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: actionCard.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: actionCard.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: actionCard.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupStyles() {
        // Header
        headerLabel.text = "Music Stem Studio"
        headerLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        headerLabel.textColor = .white
        
        versionLabel.text = "Liquid Glass UI v2 • iOS 18.0"
        versionLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        versionLabel.textColor = UIColor.systemCyan.withAlphaComponent(0.8)
        
        // Track card styling
        GlassEffect.configureGlassCard(trackCard, cornerRadius: 16)
        
        trackTitle.text = "SELECT SOUND SOURCE"
        trackTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        trackTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        trackSegmentedControl.removeAllSegments()
        for (i, song) in songs.prefix(3).enumerated() {
            trackSegmentedControl.insertSegment(withTitle: song.1, at: i, animated: false)
        }
        trackSegmentedControl.insertSegment(withTitle: "More...", at: 3, animated: false)
        trackSegmentedControl.selectedSegmentIndex = 0
        trackSegmentedControl.addTarget(self, action: #selector(songChanged), for: .valueChanged)
        
        importButton.setTitle("Import Audio", for: .normal)
        importButton.setImage(UIImage(systemName: "square.and.arrow.down.fill"), for: .normal)
        importButton.tintColor = .systemCyan
        importButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        importButton.layer.cornerRadius = 12
        importButton.layer.borderWidth = 1.0
        importButton.layer.borderColor = UIColor.systemCyan.withAlphaComponent(0.4).cgColor
        importButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.08)
        importButton.addTarget(self, action: #selector(importAudio), for: .touchUpInside)
        
        // Config card styling
        GlassEffect.configureGlassCard(configCard, cornerRadius: 16)
        
        configTitle.text = "NEURAL INFERENCE"
        configTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        configTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        qualityLabel.text = "Model Quality"
        qualityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        qualityLabel.textColor = .white
        qualitySegmentedControl.selectedSegmentIndex = 0
        
        computeLabel.text = "Hardware Unit"
        computeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        computeLabel.textColor = .white
        computeSegmentedControl.selectedSegmentIndex = 0
        
        // Action card styling
        GlassEffect.configureGlassCard(actionCard, cornerRadius: 16)
        
        actionButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.12)
        actionButton.layer.cornerRadius = 60
        actionButton.layer.borderWidth = 1.5
        actionButton.layer.borderColor = UIColor.systemCyan.cgColor
        actionButton.setImage(UIImage(systemName: "cpu"), for: .normal)
        actionButton.tintColor = .systemCyan
        actionButton.addTarget(self, action: #selector(triggerSeparation), for: .touchUpInside)
        
        // Pulse animation
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.6
        pulse.fromValue = 1.0
        pulse.toValue = 1.05
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        actionButton.layer.add(pulse, forKey: "pulse")
        
        statusLabel.text = "Ready to Separate"
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        statusLabel.textColor = .white
        
        spinner.color = .systemCyan
        spinner.hidesWhenStopped = true
    }
    
    @objc private func songChanged() {
        let index = trackSegmentedControl.selectedSegmentIndex
        if index < 3 {
            selectedSongName = songs[index].0
        }
    }
    
    @objc private func importAudio() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .video])
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func triggerSeparation() {
        statusLabel.text = "Separation started..."
    }
    
    func audioUpdated() {
        // Called when audio is updated from other screens
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        customImportedURL = url
    }
}

// MARK: - Placeholder screens
class LiquidGlassMixerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mixer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
        
        let label = UILabel()
        label.text = "Mixer Screen"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func audioUpdated() {}
}

class LiquidGlassAnalyticsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Analyzer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
        
        let label = UILabel()
        label.text = "Analytics Screen"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func audioUpdated() {}
}
