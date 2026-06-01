import UIKit
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let rootViewController = LiquidGlassRootViewController()
        window.rootViewController = rootViewController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

// MARK: - MainViewController
class MainViewController: UITabBarController {
    
    // Globally shared models and state
    let separator = CoreMLStemSeparator()
    let audioEngine = AudioEngineManager()
    let chordDetector = ChordDetectionManager()
    let beatDetector = BeatDetectionManager()
    let metronome = MetronomeManager()
    let lyricsManager = LyricsManager()
    
    // State tracking variables
    var currentSongURL: URL?
    var separatedStems: [String: URL] = [:]
    var chordSegments: [ChordSegment] = []
    var beatResult: BeatTempoResult?
    var hasActiveSeparation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }
    
    private func setupTabBar() {
        // Modern translucent dark glass appearance for iOS 18+
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.85)
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        
        // Active item styling (Neon Cyan / Electric Blue)
        appearance.stackedLayoutAppearance.selected.iconColor = .systemCyan
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemCyan,
            .font: UIFont.boldSystemFont(ofSize: 11)
        ]
        
        // Inactive item styling
        appearance.stackedLayoutAppearance.normal.iconColor = .lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.systemFont(ofSize: 11)
        ]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .systemCyan
        tabBar.unselectedItemTintColor = .lightGray
        
        // Add subtle neon border on top of tabbar
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5))
        topBorder.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.2)
        topBorder.autoresizingMask = [.flexibleWidth]
        tabBar.addSubview(topBorder)
    }
    
    private func setupViewControllers() {
        let dashboardVC = DashboardViewController()
        let mixerVC = MixerViewController()
        let analyticsVC = AnalyticsViewController()
        
        // Setup individual Tab Items
        dashboardVC.tabBarItem = UITabBarItem(
            title: "Dashboard",
            image: UIImage(systemName: "music.note.house"),
            selectedImage: UIImage(systemName: "music.note.house.fill")
        )
        
        mixerVC.tabBarItem = UITabBarItem(
            title: "Studio Mixer",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )
        
        analyticsVC.tabBarItem = UITabBarItem(
            title: "AI Analyzer",
            image: UIImage(systemName: "waveform.and.mic"),
            selectedImage: UIImage(systemName: "waveform.and.mic")
        )
        
        // Embed inside elegant navigation controllers for structured modular stacking
        let vcs = [dashboardVC, mixerVC, analyticsVC].map { vc -> UINavigationController in
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.barTintColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.9)
            nav.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 18)]
            nav.navigationBar.prefersLargeTitles = false
            return nav
        }
        
        self.viewControllers = vcs
    }
    
    // Helper function to safely find a view controller of specific type
    private func findViewController<T: UIViewController>(ofType type: T.Type, in vc: UIViewController?) -> T? {
        // Direct match
        if let match = vc as? T {
            return match
        }
        
        // Search in UINavigationController
        if let nav = vc as? UINavigationController {
            return nav.viewControllers.compactMap { findViewController(ofType: type, in: $0) }.first
        }
        
        // Search in UITabBarController
        if let tab = vc as? UITabBarController {
            return tab.viewControllers?.compactMap { findViewController(ofType: type, in: $0) }.first
        }
        
        // Search in presented view controller
        if let presented = vc?.presentedViewController {
            return findViewController(ofType: type, in: presented)
        }
        
        return nil
    }
    
    // Globally shared method to notify sub-view controllers about audio update events
    func updateAudioFile(url: URL, stems: [String: URL]?, chords: [ChordSegment], beats: BeatTempoResult?) {
        self.currentSongURL = url
        if let stems = stems {
            self.separatedStems = stems
        }
        self.chordSegments = chords
        self.beatResult = beats
        
        // Propagate events directly to individual view controllers using safe casting
        if let viewControllers = self.viewControllers {
            for vc in viewControllers {
                // Safe cast to UINavigationController and access root view controller
                if let nav = vc as? UINavigationController {
                    if let dashboard = nav.viewControllers.first as? DashboardViewController {
                        dashboard.audioUpdated()
                    }
                    if let mixer = nav.viewControllers.first as? MixerViewController {
                        mixer.audioUpdated()
                    }
                    if let analytics = nav.viewControllers.first as? AnalyticsViewController {
                        analytics.audioUpdated()
                    }
                }
            }
        }
    }
}

// MARK: - DashboardViewController
class DashboardViewController: UIViewController, UIDocumentPickerDelegate {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // UI elements
    private let headerLabel = UILabel()
    private let subheaderLabel = UILabel()
    
    private let trackSectionCard = UIView()
    private let trackSectionTitle = UILabel()
    private let trackSegmentedControl = UISegmentedControl()
    
    private let importButton = UIButton(type: .system)
    
    private let configCard = UIView()
    private let configTitle = UILabel()
    
    private let qualityLabel = UILabel()
    private let qualitySegmentedControl = UISegmentedControl(items: ["Light (FP16)", "Standard (FP32)"])
    
    private let computeLabel = UILabel()
    private let computeSegmentedControl = UISegmentedControl(items: ["All (Neural Engine)", "GPU Accel", "CPU Only"])
    
    private let separationCard = UIView()
    private let triggerButton = UIButton(type: .custom)
    private let progressLabel = UILabel()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    
    // Bundled songs list matching actual bundled files
    private let songs = [
        ("classical", "Classical Symphony"),
        ("trap", "Trap Beats"),
        ("edm", "EDM Dance"),
        ("dubstep", "Dubstep Wobble"),
        ("country", "Country Road"),
        ("drumNBass", "Drum & Bass"),
        ("folkRock", "Folk Rock"),
        ("latino", "Latino Vibes"),
        ("metal", "Heavy Metal"),
        ("reggaeton", "Reggaeton Dance"),
        ("rnb", "RnB Soul")
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        
        // Add header
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        subheaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)
        contentView.addSubview(subheaderLabel)
        
        // Add track selection card
        trackSectionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trackSectionCard)
        
        trackSectionTitle.translatesAutoresizingMaskIntoConstraints = false
        trackSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        importButton.translatesAutoresizingMaskIntoConstraints = false
        trackSectionCard.addSubview(trackSectionTitle)
        trackSectionCard.addSubview(trackSegmentedControl)
        trackSectionCard.addSubview(importButton)
        
        // Add config card
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
        
        // Add separation card
        separationCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separationCard)
        
        triggerButton.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        separationCard.addSubview(triggerButton)
        separationCard.addSubview(progressLabel)
        separationCard.addSubview(statusLabel)
        separationCard.addSubview(spinner)
        
        // Constraints
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            subheaderLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            subheaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subheaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            trackSectionCard.topAnchor.constraint(equalTo: subheaderLabel.bottomAnchor, constant: 20),
            trackSectionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            trackSectionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            trackSectionTitle.topAnchor.constraint(equalTo: trackSectionCard.topAnchor, constant: 16),
            trackSectionTitle.leadingAnchor.constraint(equalTo: trackSectionCard.leadingAnchor, constant: 16),
            trackSectionTitle.trailingAnchor.constraint(equalTo: trackSectionCard.trailingAnchor, constant: -16),
            
            trackSegmentedControl.topAnchor.constraint(equalTo: trackSectionTitle.bottomAnchor, constant: 12),
            trackSegmentedControl.leadingAnchor.constraint(equalTo: trackSectionCard.leadingAnchor, constant: 16),
            trackSegmentedControl.trailingAnchor.constraint(equalTo: trackSectionCard.trailingAnchor, constant: -16),
            trackSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            importButton.topAnchor.constraint(equalTo: trackSegmentedControl.bottomAnchor, constant: 12),
            importButton.leadingAnchor.constraint(equalTo: trackSectionCard.leadingAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: trackSectionCard.trailingAnchor, constant: -16),
            importButton.bottomAnchor.constraint(equalTo: trackSectionCard.bottomAnchor, constant: -16),
            importButton.heightAnchor.constraint(equalToConstant: 44),
            
            configCard.topAnchor.constraint(equalTo: trackSectionCard.bottomAnchor, constant: 20),
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
            computeSegmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            separationCard.topAnchor.constraint(equalTo: configCard.bottomAnchor, constant: 20),
            separationCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separationCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separationCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            triggerButton.topAnchor.constraint(equalTo: separationCard.topAnchor, constant: 24),
            triggerButton.centerXAnchor.constraint(equalTo: separationCard.centerXAnchor),
            triggerButton.widthAnchor.constraint(equalToConstant: 120),
            triggerButton.heightAnchor.constraint(equalToConstant: 120),
            
            spinner.centerXAnchor.constraint(equalTo: triggerButton.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: triggerButton.centerYAnchor),
            
            progressLabel.topAnchor.constraint(equalTo: triggerButton.bottomAnchor, constant: 16),
            progressLabel.centerXAnchor.constraint(equalTo: separationCard.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: separationCard.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: separationCard.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: separationCard.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupStyles() {
        headerLabel.text = "Music Stem Studio"
        headerLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        headerLabel.textColor = .white
        
        subheaderLabel.text = "High-Fidelity AI Audio Separator"
        subheaderLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subheaderLabel.textColor = .lightGray
        
        trackSectionTitle.text = "SELECT SOUND SOURCE"
        trackSectionTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        trackSectionTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        trackSegmentedControl.removeAllSegments()
        for (i, song) in songs.prefix(3).enumerated() {
            trackSegmentedControl.insertSegment(withTitle: song.1, at: i, animated: false)
        }
        trackSegmentedControl.insertSegment(withTitle: "More Tracks...", at: 3, animated: false)
        trackSegmentedControl.selectedSegmentIndex = 0
        trackSegmentedControl.addTarget(self, action: #selector(songChanged), for: .valueChanged)
        
        importButton.setTitle("Import Custom Audio / Extract Video", for: .normal)
        importButton.setImage(UIImage(systemName: "square.and.arrow.down.fill"), for: .normal)
        importButton.tintColor = .systemCyan
        importButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        importButton.layer.cornerRadius = 12
        importButton.layer.borderWidth = 1.0
        importButton.layer.borderColor = UIColor.systemCyan.withAlphaComponent(0.4).cgColor
        importButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.08)
        importButton.addTarget(self, action: #selector(importAudio), for: .touchUpInside)
        
        configTitle.text = "NEURAL INFERENCE PARAMS"
        configTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        configTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        qualityLabel.text = "Model Processing Quality"
        qualityLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        qualityLabel.textColor = .white
        
        qualitySegmentedControl.selectedSegmentIndex = 0 // Light
        
        computeLabel.text = "Hardware Execution Unit"
        computeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        computeLabel.textColor = .white
        
        computeSegmentedControl.selectedSegmentIndex = 0 // ANE
        
        for card in [trackSectionCard, configCard, separationCard] {
            card.backgroundColor = UIColor(white: 0.08, alpha: 0.6)
            card.layer.cornerRadius = 16
            card.layer.borderWidth = 0.5
            card.layer.borderColor = UIColor(white: 0.2, alpha: 0.3).cgColor
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.3
            card.layer.shadowOffset = CGSize(width: 0, height: 4)
            card.layer.shadowRadius = 8
        }
        
        triggerButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.12)
        triggerButton.layer.cornerRadius = 60
        triggerButton.layer.borderWidth = 1.5
        triggerButton.layer.borderColor = UIColor.systemCyan.cgColor
        triggerButton.setImage(UIImage(systemName: "cpu"), for: .normal)
        triggerButton.tintColor = .systemCyan
        triggerButton.addTarget(self, action: #selector(triggerSeparation), for: .touchUpInside)
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.6
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        triggerButton.layer.add(pulseAnimation, forKey: "pulse")
        
        progressLabel.text = "Ready to Separate"
        progressLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        progressLabel.textColor = .white
        
        statusLabel.text = "Select a song or import custom files to begin."
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .lightGray
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        spinner.color = .systemCyan
        spinner.hidesWhenStopped = true
    }
    
    @objc private func songChanged() {
        let index = trackSegmentedControl.selectedSegmentIndex
        if index < 3 {
            customImportedURL = nil
            selectedSongName = songs[index].0
            statusLabel.text = "Selected track: \(songs[index].1). CoreML will separate it into 6 isolated audio channels."
        } else {
            let alert = UIAlertController(title: "Select Bundled Track", message: "Choose from pre-bundled high-fidelity audio samples", preferredStyle: .actionSheet)
            
            for song in songs {
                alert.addAction(UIAlertAction(title: song.1, style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.customImportedURL = nil
                    self.selectedSongName = song.0
                    self.statusLabel.text = "Selected track: \(song.1). CoreML will separate it into 6 isolated audio channels."
                    self.trackSegmentedControl.setTitle(song.1, forSegmentAt: 3)
                    self.trackSegmentedControl.selectedSegmentIndex = 3
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                guard let self = self else { return }
                self.trackSegmentedControl.selectedSegmentIndex = 0
                self.songChanged()
            }))
            
            present(alert, animated: true)
        }
    }
    
    private func selectSong(index: Int) {
        trackSegmentedControl.selectedSegmentIndex = index
        songChanged()
    }
    
    @objc private func importAudio() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio, .video])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else { return }
        
        let isSecured = pickedURL.startAccessingSecurityScopedResource()
        defer { if isSecured { pickedURL.stopAccessingSecurityScopedResource() } }
        
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(pickedURL.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: pickedURL, to: destinationURL)
            self.customImportedURL = destinationURL
            self.statusLabel.text = "Imported successfully: \(destinationURL.lastPathComponent). Tap circle to initiate CoreML separation."
            trackSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        } catch {
            statusLabel.text = "Import error: \(error.localizedDescription)"
        }
    }
    
    @objc private func triggerSeparation() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        
        if mainTabBar.hasActiveSeparation {
            statusLabel.text = "Separation already running in background..."
            return
        }
        
        let inputURL: URL
        var audioName = selectedSongName
        if let customURL = customImportedURL {
            inputURL = customURL
            audioName = customURL.deletingPathExtension().lastPathComponent
        } else {
            guard let bundleURL = Bundle.main.url(forResource: selectedSongName, withExtension: "caf") else {
                statusLabel.text = "Bundled track file \(selectedSongName).caf not found in app bundle."
                return
            }
            inputURL = bundleURL
        }
        
        mainTabBar.hasActiveSeparation = true
        spinner.startAnimating()
        triggerButton.isEnabled = false
        triggerButton.layer.borderColor = UIColor.lightGray.cgColor
        triggerButton.tintColor = .lightGray
        triggerButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.08)
        
        progressLabel.text = "Processing..."
        statusLabel.text = "Preparing offline models..."
        
        Task {
            do {
                let quality = qualitySegmentedControl.selectedSegmentIndex == 0 ? "Model Ringan" : "Standard"
                let mode = computeSegmentedControl.selectedSegmentIndex == 0 ? "Neural Engine" : (computeSegmentedControl.selectedSegmentIndex == 1 ? "GPU Accel" : "CPU Only")
                
                print("[DashboardVC] Starting CoreML stem separation: \(inputURL.lastPathComponent)")
                
                let stemURLs = try await mainTabBar.separator.separate(
                    audioURL: inputURL,
                    processingMode: mode,
                    modelQuality: quality
                ) { [weak self] (log, progress) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.progressLabel.text = "Processing: \(Int(progress * 100))%"
                        self.statusLabel.text = log
                    }
                }
                
                try mainTabBar.audioEngine.loadStemFiles(stemURLs)
                
                print("[DashboardVC] CoreML Separation succeeded. Initiating Beat and Chord detection...")
                
                mainTabBar.lyricsManager.loadLyrics(for: audioName)
                
                let beatResult = try? await mainTabBar.beatDetector.analyzeBeats(audioURL: inputURL)
                let chordSegments = (try? await mainTabBar.chordDetector.analyzeChords(audioURL: inputURL)) ?? []
                
                DispatchQueue.main.async {
                    mainTabBar.hasActiveSeparation = false
                    self.spinner.stopAnimating()
                    self.resetTriggerButton()
                    
                    self.progressLabel.text = "Separation Complete"
                    self.statusLabel.text = "Stems extracted successfully! Autoplaying in Studio Mixer."
                    
                    mainTabBar.updateAudioFile(
                        url: inputURL,
                        stems: stemURLs,
                        chords: chordSegments,
                        beats: beatResult
                    )
                    
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        mainTabBar.selectedIndex = 1
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    mainTabBar.hasActiveSeparation = false
                    self.spinner.stopAnimating()
                    self.resetTriggerButton()
                    
                    self.progressLabel.text = "Separation Failed"
                    self.statusLabel.text = "Error: \(error.localizedDescription)"
                    
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func resetTriggerButton() {
        triggerButton.isEnabled = true
        triggerButton.layer.borderColor = UIColor.systemCyan.cgColor
        triggerButton.tintColor = .systemCyan
        triggerButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.12)
    }
    
    func audioUpdated() {}
}
