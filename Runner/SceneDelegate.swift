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
        let mainVC = MainViewController()
        window.rootViewController = mainVC
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

// MARK: - MixerViewController
class MixerViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Master Console UI
    private let masterCard = UIView()
    private let songTitleLabel = UILabel()
    private let durationLabel = UILabel()
    private let timeLabel = UILabel()
    private let seekSlider = UISlider()
    
    private let playButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let metronomeButton = UIButton(type: .system)
    
    // DSP Adjustments
    private let dspCard = UIView()
    private let dspTitle = UILabel()
    
    private let speedLabel = UILabel()
    private let speedValueLabel = UILabel()
    private let speedSlider = UISlider()
    
    private let pitchLabel = UILabel()
    private let pitchValueLabel = UILabel()
    private let pitchSlider = UISlider()
    
    // Stem Mixer Strips Container
    private let mixerCard = UIView()
    private let mixerTitle = UILabel()
    private let stemStopsStack = UIStackView()
    
    // Export UI
    private let exportButton = UIButton(type: .system)
    private let exportSpinner = UIActivityIndicatorView(style: .medium)
    
    // Channel strip variables tracking state
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
    private let stemDisplayNames = [
        "vocals": "Vocals",
        "drums": "Drums",
        "bass": "Bass Guitar",
        "guitar": "Acoustic Guitar",
        "piano": "Piano / Synth",
        "other": "Others"
    ]
    private let stemColors: [String: UIColor] = [
        "vocals": .systemCyan,
        "drums": .systemPurple,
        "bass": .systemPink,
        "guitar": .systemYellow,
        "piano": .systemGreen,
        "other": .systemOrange
    ]
    
    private var volumeSliders: [String: UISlider] = [:]
    private var muteButtons: [String: UIButton] = [:]
    private var soloButtons: [String: UIButton] = [:]
    private var visualizerBars: [String: [UIView]] = [:]
    
    private var isPlaying = false
    private var isMetronomeOn = false
    private var playTimer: Timer?
    private var visualizerTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Studio Mixer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
        
        setupLayout()
        setupStyles()
        buildMixerStrips()
        updateUIState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        audioUpdated()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimers()
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
        
        // Add Master Card
        masterCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(masterCard)
        
        songTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        seekSlider.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        metronomeButton.translatesAutoresizingMaskIntoConstraints = false
        
        masterCard.addSubview(songTitleLabel)
        masterCard.addSubview(timeLabel)
        masterCard.addSubview(durationLabel)
        masterCard.addSubview(seekSlider)
        masterCard.addSubview(playButton)
        masterCard.addSubview(stopButton)
        masterCard.addSubview(metronomeButton)
        
        // Add Stem Mixer Card
        mixerCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mixerCard)
        
        mixerTitle.translatesAutoresizingMaskIntoConstraints = false
        stemStopsStack.translatesAutoresizingMaskIntoConstraints = false
        
        mixerCard.addSubview(mixerTitle)
        mixerCard.addSubview(stemStopsStack)
        
        // Add DSP Card
        dspCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dspCard)
        
        dspTitle.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        speedValueLabel.translatesAutoresizingMaskIntoConstraints = false
        speedSlider.translatesAutoresizingMaskIntoConstraints = false
        
        pitchLabel.translatesAutoresizingMaskIntoConstraints = false
        pitchValueLabel.translatesAutoresizingMaskIntoConstraints = false
        pitchSlider.translatesAutoresizingMaskIntoConstraints = false
        
        dspCard.addSubview(dspTitle)
        dspCard.addSubview(speedLabel)
        dspCard.addSubview(speedValueLabel)
        dspCard.addSubview(speedSlider)
        dspCard.addSubview(pitchLabel)
        dspCard.addSubview(pitchValueLabel)
        dspCard.addSubview(pitchSlider)
        
        // Add Export Button
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportSpinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exportButton)
        exportButton.addSubview(exportSpinner)
        
        // Constraints
        NSLayoutConstraint.activate([
            masterCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            masterCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            masterCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            songTitleLabel.topAnchor.constraint(equalTo: masterCard.topAnchor, constant: 16),
            songTitleLabel.leadingAnchor.constraint(equalTo: masterCard.leadingAnchor, constant: 16),
            songTitleLabel.trailingAnchor.constraint(equalTo: masterCard.trailingAnchor, constant: -16),
            
            seekSlider.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 16),
            seekSlider.leadingAnchor.constraint(equalTo: masterCard.leadingAnchor, constant: 16),
            seekSlider.trailingAnchor.constraint(equalTo: masterCard.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: masterCard.leadingAnchor, constant: 16),
            
            durationLabel.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 6),
            durationLabel.trailingAnchor.constraint(equalTo: masterCard.trailingAnchor, constant: -16),
            
            playButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            playButton.centerXAnchor.constraint(equalTo: masterCard.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 64),
            playButton.heightAnchor.constraint(equalToConstant: 64),
            
            stopButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            stopButton.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -24),
            stopButton.widthAnchor.constraint(equalToConstant: 44),
            stopButton.heightAnchor.constraint(equalToConstant: 44),
            
            metronomeButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            metronomeButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 24),
            metronomeButton.widthAnchor.constraint(equalToConstant: 44),
            metronomeButton.heightAnchor.constraint(equalToConstant: 44),
            metronomeButton.bottomAnchor.constraint(equalTo: masterCard.bottomAnchor, constant: -16),
            
            mixerCard.topAnchor.constraint(equalTo: masterCard.bottomAnchor, constant: 16),
            mixerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mixerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            mixerTitle.topAnchor.constraint(equalTo: mixerCard.topAnchor, constant: 16),
            mixerTitle.leadingAnchor.constraint(equalTo: mixerCard.leadingAnchor, constant: 16),
            mixerTitle.trailingAnchor.constraint(equalTo: mixerCard.trailingAnchor, constant: -16),
            
            stemStopsStack.topAnchor.constraint(equalTo: mixerTitle.bottomAnchor, constant: 12),
            stemStopsStack.leadingAnchor.constraint(equalTo: mixerCard.leadingAnchor, constant: 16),
            stemStopsStack.trailingAnchor.constraint(equalTo: mixerCard.trailingAnchor, constant: -16),
            stemStopsStack.bottomAnchor.constraint(equalTo: mixerCard.bottomAnchor, constant: -16),
            
            dspCard.topAnchor.constraint(equalTo: mixerCard.bottomAnchor, constant: 16),
            dspCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dspCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dspTitle.topAnchor.constraint(equalTo: dspCard.topAnchor, constant: 16),
            dspTitle.leadingAnchor.constraint(equalTo: dspCard.leadingAnchor, constant: 16),
            
            speedLabel.topAnchor.constraint(equalTo: dspTitle.bottomAnchor, constant: 16),
            speedLabel.leadingAnchor.constraint(equalTo: dspCard.leadingAnchor, constant: 16),
            
            speedValueLabel.centerYAnchor.constraint(equalTo: speedLabel.centerYAnchor),
            speedValueLabel.trailingAnchor.constraint(equalTo: dspCard.trailingAnchor, constant: -16),
            
            speedSlider.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 8),
            speedSlider.leadingAnchor.constraint(equalTo: dspCard.leadingAnchor, constant: 16),
            speedSlider.trailingAnchor.constraint(equalTo: dspCard.trailingAnchor, constant: -16),
            
            pitchLabel.topAnchor.constraint(equalTo: speedSlider.bottomAnchor, constant: 16),
            pitchLabel.leadingAnchor.constraint(equalTo: dspCard.leadingAnchor, constant: 16),
            
            pitchValueLabel.centerYAnchor.constraint(equalTo: pitchLabel.centerYAnchor),
            pitchValueLabel.trailingAnchor.constraint(equalTo: dspCard.trailingAnchor, constant: -16),
            
            pitchSlider.topAnchor.constraint(equalTo: pitchLabel.bottomAnchor, constant: 8),
            pitchSlider.leadingAnchor.constraint(equalTo: dspCard.leadingAnchor, constant: 16),
            pitchSlider.trailingAnchor.constraint(equalTo: dspCard.trailingAnchor, constant: -16),
            pitchSlider.bottomAnchor.constraint(equalTo: dspCard.bottomAnchor, constant: -16),
            
            exportButton.topAnchor.constraint(equalTo: dspCard.bottomAnchor, constant: 20),
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            exportButton.heightAnchor.constraint(equalToConstant: 48),
            
            exportSpinner.centerYAnchor.constraint(equalTo: exportButton.centerYAnchor),
            exportSpinner.trailingAnchor.constraint(equalTo: exportButton.titleLabel!.leadingAnchor, constant: -12)
        ])
    }
    
    private func setupStyles() {
        songTitleLabel.text = "No track loaded"
        songTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        songTitleLabel.textColor = .white
        songTitleLabel.textAlignment = .center
        
        durationLabel.text = "00:00"
        durationLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = .lightGray
        
        timeLabel.text = "00:00"
        timeLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .lightGray
        
        seekSlider.minimumValue = 0
        seekSlider.maximumValue = 1.0
        seekSlider.value = 0
        seekSlider.tintColor = .systemCyan
        seekSlider.thumbTintColor = .white
        seekSlider.addTarget(self, action: #selector(seekSliderChanged), for: .valueChanged)
        
        playButton.backgroundColor = UIColor.systemCyan
        playButton.tintColor = .black
        playButton.layer.cornerRadius = 32
        playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)), for: .normal)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        
        stopButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
        stopButton.tintColor = .white
        stopButton.layer.cornerRadius = 22
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        
        metronomeButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
        metronomeButton.tintColor = .white
        metronomeButton.layer.cornerRadius = 22
        metronomeButton.setImage(UIImage(systemName: "metronome"), for: .normal)
        metronomeButton.addTarget(self, action: #selector(metronomeTapped), for: .touchUpInside)
        
        mixerTitle.text = "ISOLATED AUDIO MIXER"
        mixerTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        mixerTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        stemStopsStack.axis = .vertical
        stemStopsStack.spacing = 16
        stemStopsStack.distribution = .equalSpacing
        
        dspTitle.text = "REAL-TIME DSP ENGINE ADJUSTMENTS"
        dspTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        dspTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        speedLabel.text = "Playback Speed (Tempo)"
        speedLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        speedLabel.textColor = .white
        
        speedValueLabel.text = "1.00x"
        speedValueLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        speedValueLabel.textColor = .systemCyan
        
        speedSlider.minimumValue = 0.5
        speedSlider.maximumValue = 2.0
        speedSlider.value = 1.0
        speedSlider.tintColor = .systemCyan
        speedSlider.addTarget(self, action: #selector(speedChanged), for: .valueChanged)
        
        pitchLabel.text = "Pitch Shift (Key Change)"
        pitchLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        pitchLabel.textColor = .white
        
        pitchValueLabel.text = "0 semitones"
        pitchValueLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        pitchValueLabel.textColor = .systemCyan
        
        pitchSlider.minimumValue = -12
        pitchSlider.maximumValue = 12
        pitchSlider.value = 0
        pitchSlider.tintColor = .systemCyan
        pitchSlider.addTarget(self, action: #selector(pitchChanged), for: .valueChanged)
        
        exportButton.setTitle("Export Mix to Stereo M4A", for: .normal)
        exportButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        exportButton.tintColor = .black
        exportButton.backgroundColor = .systemCyan
        exportButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        exportButton.layer.cornerRadius = 14
        exportButton.addTarget(self, action: #selector(exportMix), for: .touchUpInside)
        
        exportSpinner.color = .black
        exportSpinner.hidesWhenStopped = true
        
        for card in [masterCard, mixerCard, dspCard] {
            card.backgroundColor = UIColor(white: 0.08, alpha: 0.6)
            card.layer.cornerRadius = 16
            card.layer.borderWidth = 0.5
            card.layer.borderColor = UIColor(white: 0.2, alpha: 0.3).cgColor
        }
    }
    
    private func buildMixerStrips() {
        stemStopsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        volumeSliders.removeAll()
        muteButtons.removeAll()
        soloButtons.removeAll()
        visualizerBars.removeAll()
        
        for name in stemNames {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            stemStopsStack.addArrangedSubview(container)
            
            let color = stemColors[name] ?? .white
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = stemDisplayNames[name]?.uppercased()
            label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            label.textColor = color
            container.addSubview(label)
            
            let muteBtn = UIButton(type: .system)
            muteBtn.translatesAutoresizingMaskIntoConstraints = false
            muteBtn.setTitle("MUTE", for: .normal)
            muteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            muteBtn.tintColor = .lightGray
            muteBtn.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
            muteBtn.layer.cornerRadius = 6
            muteBtn.layer.borderWidth = 0.5
            muteBtn.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
            muteBtn.accessibilityIdentifier = "\(name)_mute"
            muteBtn.addTarget(self, action: #selector(muteTapped(_:)), for: .touchUpInside)
            container.addSubview(muteBtn)
            muteButtons[name] = muteBtn
            
            let soloBtn = UIButton(type: .system)
            soloBtn.translatesAutoresizingMaskIntoConstraints = false
            soloBtn.setTitle("SOLO", for: .normal)
            soloBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            soloBtn.tintColor = .lightGray
            soloBtn.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
            soloBtn.layer.cornerRadius = 6
            soloBtn.layer.borderWidth = 0.5
            soloBtn.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
            soloBtn.accessibilityIdentifier = "\(name)_solo"
            soloBtn.addTarget(self, action: #selector(soloTapped(_:)), for: .touchUpInside)
            container.addSubview(soloBtn)
            soloButtons[name] = soloBtn
            
            let slider = UISlider()
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.minimumValue = 0.0
            slider.maximumValue = 1.0
            slider.value = 1.0
            slider.tintColor = color
            slider.accessibilityIdentifier = name
            slider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)
            container.addSubview(slider)
            volumeSliders[name] = slider
            
            let meterStack = UIStackView()
            meterStack.translatesAutoresizingMaskIntoConstraints = false
            meterStack.axis = .horizontal
            meterStack.spacing = 2
            meterStack.distribution = .fillEqually
            container.addSubview(meterStack)
            
            var bars: [UIView] = []
            for _ in 0..<4 {
                let bar = UIView()
                bar.translatesAutoresizingMaskIntoConstraints = false
                bar.backgroundColor = color.withAlphaComponent(0.2)
                bar.layer.cornerRadius = 1
                meterStack.addArrangedSubview(bar)
                bars.append(bar)
            }
            visualizerBars[name] = bars
            
            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalToConstant: 48),
                
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.widthAnchor.constraint(equalToConstant: 100),
                
                meterStack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
                meterStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                meterStack.widthAnchor.constraint(equalToConstant: 64),
                meterStack.heightAnchor.constraint(equalToConstant: 16),
                
                muteBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                muteBtn.trailingAnchor.constraint(equalTo: soloBtn.leadingAnchor, constant: -8),
                muteBtn.widthAnchor.constraint(equalToConstant: 44),
                muteBtn.heightAnchor.constraint(equalToConstant: 26),
                
                soloBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                soloBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                soloBtn.widthAnchor.constraint(equalToConstant: 44),
                soloBtn.heightAnchor.constraint(equalToConstant: 26),
                
                slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
                slider.trailingAnchor.constraint(equalTo: muteBtn.leadingAnchor, constant: -12)
            ])
        }
    }
    
    func audioUpdated() {
        guard let mainTabBar = self.tabBarController as? MainViewController, isViewLoaded else { return }
        
        if let currentURL = mainTabBar.currentSongURL {
            songTitleLabel.text = currentURL.deletingPathExtension().lastPathComponent.uppercased()
            
            if let firstFile = mainTabBar.separatedStems.values.first {
                do {
                    let audioFile = try AVAudioFile(forReading: firstFile)
                    let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
                    durationLabel.text = formatSeconds(duration)
                    seekSlider.maximumValue = Float(duration)
                } catch {
                    durationLabel.text = "03:00"
                    seekSlider.maximumValue = 180.0
                }
            } else {
                durationLabel.text = "03:00"
                seekSlider.maximumValue = 180.0
            }
        } else {
            songTitleLabel.text = "No Track Loaded"
            durationLabel.text = "00:00"
            seekSlider.maximumValue = 1.0
        }
        
        seekSlider.value = 0
        timeLabel.text = "00:00"
        stopTapped()
    }
    
    private func updateUIState() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        if isPlaying {
            playButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
            playButton.backgroundColor = .systemYellow
        } else {
            playButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
            playButton.backgroundColor = .systemCyan
        }
        
        if isMetronomeOn {
            metronomeButton.backgroundColor = .systemCyan
            metronomeButton.tintColor = .black
        } else {
            metronomeButton.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
            metronomeButton.tintColor = .white
        }
    }
    
    @objc private func playTapped() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        guard mainTabBar.currentSongURL != nil else {
            let alert = UIAlertController(title: "No Stems Found", message: "Please select a track in Dashboard and press separate audio first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        
        isPlaying.toggle()
        updateUIState()
        
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        if isPlaying {
            do {
                try mainTabBar.audioEngine.play()
                startTimers()
                
                if isMetronomeOn, let bpm = mainTabBar.beatResult?.tempo {
                    mainTabBar.metronome.start(bpm: bpm)
                }
            } catch {
                print("AVAudioEngine: Playback start failed: \(error)")
                isPlaying = false
                updateUIState()
            }
        } else {
            mainTabBar.audioEngine.pause()
            mainTabBar.metronome.stop()
            stopTimers()
        }
    }
    
    @objc private func stopTapped() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        
        isPlaying = false
        updateUIState()
        
        mainTabBar.audioEngine.stop()
        mainTabBar.metronome.stop()
        stopTimers()
        
        seekSlider.value = 0
        timeLabel.text = "00:00"
        mainTabBar.audioEngine.seek(to: 0)
    }
    
    @objc private func seekSliderChanged() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        let time = Double(seekSlider.value)
        timeLabel.text = formatSeconds(time)
        mainTabBar.audioEngine.seek(to: time)
    }
    
    @objc private func volumeSliderChanged(_ sender: UISlider) {
        guard let mainTabBar = self.tabBarController as? MainViewController,
              let name = sender.accessibilityIdentifier else { return }
        
        let vol = sender.value
        mainTabBar.audioEngine.setStemVolume(stem: name, volume: vol)
        
        if vol > 0.01, let muteBtn = muteButtons[name] {
            muteBtn.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
            muteBtn.tintColor = .lightGray
        }
    }
    
    @objc private func muteTapped(_ sender: UIButton) {
        guard let mainTabBar = self.tabBarController as? MainViewController,
              let id = sender.accessibilityIdentifier,
              let name = id.components(separatedBy: "_").first else { return }
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        
        guard let slider = volumeSliders[name] else { return }
        let currentVol = slider.value
        
        if currentVol > 0.0 {
            slider.value = 0.0
            mainTabBar.audioEngine.setStemVolume(stem: name, volume: 0.0)
            sender.backgroundColor = .systemPink
            sender.tintColor = .white
        } else {
            slider.value = 1.0
            mainTabBar.audioEngine.setStemVolume(stem: name, volume: 1.0)
            sender.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
            sender.tintColor = .lightGray
        }
    }
    
    @objc private func soloTapped(_ sender: UIButton) {
        guard let mainTabBar = self.tabBarController as? MainViewController,
              let id = sender.accessibilityIdentifier,
              let name = id.components(separatedBy: "_").first else { return }
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        
        let isAlreadySoloed = sender.backgroundColor == .systemCyan
        
        if isAlreadySoloed {
            for stem in stemNames {
                volumeSliders[stem]?.value = 1.0
                mainTabBar.audioEngine.setStemVolume(stem: stem, volume: 1.0)
                soloButtons[stem]?.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
                soloButtons[stem]?.tintColor = .lightGray
                muteButtons[stem]?.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
                muteButtons[stem]?.tintColor = .lightGray
            }
        } else {
            mainTabBar.audioEngine.soloStem(name)
            
            for stem in stemNames {
                if stem == name {
                    volumeSliders[stem]?.value = 1.0
                    soloButtons[stem]?.backgroundColor = .systemCyan
                    soloButtons[stem]?.tintColor = .black
                    muteButtons[stem]?.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
                    muteButtons[stem]?.tintColor = .lightGray
                } else {
                    volumeSliders[stem]?.value = 0.0
                    soloButtons[stem]?.backgroundColor = UIColor(white: 0.15, alpha: 0.6)
                    soloButtons[stem]?.tintColor = .lightGray
                    muteButtons[stem]?.backgroundColor = .systemPink
                    muteButtons[stem]?.tintColor = .white
                }
            }
        }
    }
    
    @objc private func speedChanged() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        let speed = speedSlider.value
        speedValueLabel.text = String(format: "%.2fx", speed)
        mainTabBar.audioEngine.setPlaybackSpeed(speed)
        
        if isMetronomeOn, let tempo = mainTabBar.beatResult?.tempo {
            mainTabBar.metronome.updateBPM(tempo * Double(speed))
        }
    }
    
    @objc private func pitchChanged() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        let pitch = round(pitchSlider.value)
        pitchSlider.value = pitch
        
        let pitchStr = pitch > 0 ? "+\(Int(pitch)) semitones" : (pitch < 0 ? "\(Int(pitch)) semitones" : "0 semitones")
        pitchValueLabel.text = pitchStr
        mainTabBar.audioEngine.setPitchShift(pitch)
    }
    
    @objc private func metronomeTapped() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        
        isMetronomeOn.toggle()
        updateUIState()
        
        if isMetronomeOn {
            if isPlaying, let tempo = mainTabBar.beatResult?.tempo {
                let speedFactor = Double(speedSlider.value)
                mainTabBar.metronome.start(bpm: tempo * speedFactor)
            }
        } else {
            mainTabBar.metronome.stop()
        }
    }
    
    @objc private func exportMix() {
        guard let mainTabBar = self.tabBarController as? MainViewController else { return }
        guard mainTabBar.currentSongURL != nil else { return }
        
        var vols: [String: Float] = [:]
        for stem in stemNames {
            vols[stem] = volumeSliders[stem]?.value ?? 1.0
        }
        
        exportButton.isEnabled = false
        exportButton.setTitle("Rendering Offline...", for: .normal)
        exportSpinner.startAnimating()
        
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("Studio_Mix_\(UUID().uuidString).m4a")
        
        Task {
            do {
                try await mainTabBar.audioEngine.exportStemMix(volumes: vols, outputURL: outputURL)
                
                DispatchQueue.main.async {
                    self.exportSpinner.stopAnimating()
                    self.exportButton.isEnabled = true
                    self.exportButton.setTitle("Export Mix to Stereo M4A", for: .normal)
                    
                    let activityVC = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
                    if let popoverController = activityVC.popoverPresentationController {
                        popoverController.sourceView = self.exportButton
                        popoverController.sourceRect = self.exportButton.bounds
                    }
                    self.present(activityVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.exportSpinner.stopAnimating()
                    self.exportButton.isEnabled = true
                    self.exportButton.setTitle("Export Mix Failed", for: .normal)
                    
                    let alert = UIAlertController(title: "Export Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func startTimers() {
        stopTimers()
        
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let mainTabBar = self.tabBarController as? MainViewController else { return }
            
            let currentVal = self.seekSlider.value
            let maxVal = self.seekSlider.maximumValue
            let speedFactor = self.speedSlider.value
            
            let increment = Float(0.1) * speedFactor
            let newVal = min(currentVal + increment, maxVal)
            
            self.seekSlider.value = newVal
            self.timeLabel.text = self.formatSeconds(Double(newVal))
            
            if let analyticsNav = mainTabBar.viewControllers?[2] as? UINavigationController,
               let analytics = analyticsNav.viewControllers.first as? AnalyticsViewController {
                analytics.updatePlaybackPosition(time: Double(newVal))
            }
            
            if newVal >= maxVal {
                self.stopTapped()
            }
        }
        
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            for stem in self.stemNames {
                guard let bars = self.visualizerBars[stem],
                      let slider = self.volumeSliders[stem] else { continue }
                
                let vol = slider.value
                let isStemMuted = vol < 0.01
                
                for bar in bars {
                    if isStemMuted {
                        bar.backgroundColor = self.stemColors[stem]?.withAlphaComponent(0.1)
                        bar.transform = .identity
                    } else {
                        let factor = CGFloat(Float.random(in: 0.2...1.0) * vol)
                        let heightScale = factor * 2.5
                        
                        bar.backgroundColor = self.stemColors[stem]?.withAlphaComponent(0.3 + factor * 0.7)
                        bar.transform = CGAffineTransform(scaleX: 1.0, y: heightScale)
                    }
                }
            }
        }
    }
    
    private func stopTimers() {
        playTimer?.invalidate()
        playTimer = nil
        
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        
        for stem in stemNames {
            guard let bars = visualizerBars[stem] else { continue }
            for bar in bars {
                bar.backgroundColor = stemColors[stem]?.withAlphaComponent(0.2)
                bar.transform = .identity
            }
        }
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let totalSecs = Int(seconds)
        let mins = totalSecs / 60
        let secs = totalSecs % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - AnalyticsViewController
class AnalyticsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let segmentControl = UISegmentedControl(items: ["Chords & Progression", "Beat Tracker Grid", "Karaoke Lyrics Sheet"])
    private let containerView = UIView()
    
    // 1. Chords View UI
    private let chordsContainer = UIView()
    private let currentChordCard = UIView()
    private let currentChordTitle = UILabel()
    private let currentChordLabel = UILabel()
    private let chordRootLabel = UILabel()
    private let teleprompterTitle = UILabel()
    private let chordsTableView = UITableView()
    
    // 2. Beat Metronome View UI
    private let beatContainer = UIView()
    private let metronomeTitle = UILabel()
    private let bpmLabel = UILabel()
    private let pulseCircle = UIView()
    private let downbeatIndicator = UIView()
    private let beatIndicatorsStack = UIStackView()
    private var beatIndicatorLights: [UIView] = []
    
    // 3. Lyrics View UI
    private let lyricsContainer = UIView()
    private let lyricsTableView = UITableView()
    
    // State variables
    private var chordsList: [ChordSegment] = []
    private var lyricLines: [LyricLine] = []
    private var beatsList: [BeatMarker] = []
    private var downbeatsList: [Double] = []
    private var tempoBPM: Double = 120.0
    
    private var activeChordIndex = -1
    private var activeLyricIndex = -1
    private var lastBeatIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Analyzer"
        view.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
        
        setupLayout()
        setupStyles()
        setupTables()
        showSegment(index: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        audioUpdated()
    }
    
    private func setupLayout() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),
            
            containerView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        setupChordsLayout()
        setupBeatLayout()
        setupLyricsLayout()
    }
    
    private func setupChordsLayout() {
        chordsContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chordsContainer)
        
        currentChordCard.translatesAutoresizingMaskIntoConstraints = false
        currentChordTitle.translatesAutoresizingMaskIntoConstraints = false
        currentChordLabel.translatesAutoresizingMaskIntoConstraints = false
        chordRootLabel.translatesAutoresizingMaskIntoConstraints = false
        teleprompterTitle.translatesAutoresizingMaskIntoConstraints = false
        chordsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        chordsContainer.addSubview(currentChordCard)
        currentChordCard.addSubview(currentChordTitle)
        currentChordCard.addSubview(currentChordLabel)
        currentChordCard.addSubview(chordRootLabel)
        
        chordsContainer.addSubview(teleprompterTitle)
        chordsContainer.addSubview(chordsTableView)
        
        NSLayoutConstraint.activate([
            chordsContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            chordsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            chordsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            chordsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            currentChordCard.topAnchor.constraint(equalTo: chordsContainer.topAnchor, constant: 16),
            currentChordCard.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: 16),
            currentChordCard.trailingAnchor.constraint(equalTo: chordsContainer.trailingAnchor, constant: -16),
            currentChordCard.heightAnchor.constraint(equalToConstant: 140),
            
            currentChordTitle.topAnchor.constraint(equalTo: currentChordCard.topAnchor, constant: 14),
            currentChordTitle.centerXAnchor.constraint(equalTo: currentChordCard.centerXAnchor),
            
            currentChordLabel.topAnchor.constraint(equalTo: currentChordTitle.bottomAnchor, constant: 4),
            currentChordLabel.centerXAnchor.constraint(equalTo: currentChordCard.centerXAnchor),
            
            chordRootLabel.topAnchor.constraint(equalTo: currentChordLabel.bottomAnchor, constant: 2),
            chordRootLabel.centerXAnchor.constraint(equalTo: currentChordCard.centerXAnchor),
            
            teleprompterTitle.topAnchor.constraint(equalTo: currentChordCard.bottomAnchor, constant: 20),
            teleprompterTitle.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: 16),
            
            chordsTableView.topAnchor.constraint(equalTo: teleprompterTitle.bottomAnchor, constant: 8),
            chordsTableView.leadingAnchor.constraint(equalTo: chordsContainer.leadingAnchor, constant: 16),
            chordsTableView.trailingAnchor.constraint(equalTo: chordsContainer.trailingAnchor, constant: -16),
            chordsTableView.bottomAnchor.constraint(equalTo: chordsContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupBeatLayout() {
        beatContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(beatContainer)
        
        metronomeTitle.translatesAutoresizingMaskIntoConstraints = false
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false
        pulseCircle.translatesAutoresizingMaskIntoConstraints = false
        downbeatIndicator.translatesAutoresizingMaskIntoConstraints = false
        beatIndicatorsStack.translatesAutoresizingMaskIntoConstraints = false
        
        beatContainer.addSubview(metronomeTitle)
        beatContainer.addSubview(bpmLabel)
        beatContainer.addSubview(pulseCircle)
        beatContainer.addSubview(downbeatIndicator)
        beatContainer.addSubview(beatIndicatorsStack)
        
        NSLayoutConstraint.activate([
            beatContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            beatContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            beatContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            beatContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            metronomeTitle.topAnchor.constraint(equalTo: beatContainer.topAnchor, constant: 24),
            metronomeTitle.centerXAnchor.constraint(equalTo: beatContainer.centerXAnchor),
            
            bpmLabel.topAnchor.constraint(equalTo: metronomeTitle.bottomAnchor, constant: 6),
            bpmLabel.centerXAnchor.constraint(equalTo: beatContainer.centerXAnchor),
            
            pulseCircle.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 40),
            pulseCircle.centerXAnchor.constraint(equalTo: beatContainer.centerXAnchor),
            pulseCircle.widthAnchor.constraint(equalToConstant: 180),
            pulseCircle.heightAnchor.constraint(equalToConstant: 180),
            
            downbeatIndicator.topAnchor.constraint(equalTo: pulseCircle.bottomAnchor, constant: 40),
            downbeatIndicator.centerXAnchor.constraint(equalTo: beatContainer.centerXAnchor),
            downbeatIndicator.widthAnchor.constraint(equalToConstant: 24),
            downbeatIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            beatIndicatorsStack.topAnchor.constraint(equalTo: downbeatIndicator.bottomAnchor, constant: 24),
            beatIndicatorsStack.centerXAnchor.constraint(equalTo: beatContainer.centerXAnchor),
            beatIndicatorsStack.widthAnchor.constraint(equalToConstant: 160),
            beatIndicatorsStack.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupLyricsLayout() {
        lyricsContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lyricsContainer)
        
        lyricsTableView.translatesAutoresizingMaskIntoConstraints = false
        lyricsContainer.addSubview(lyricsTableView)
        
        NSLayoutConstraint.activate([
            lyricsContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            lyricsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lyricsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lyricsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            lyricsTableView.topAnchor.constraint(equalTo: lyricsContainer.topAnchor, constant: 16),
            lyricsTableView.leadingAnchor.constraint(equalTo: lyricsContainer.leadingAnchor, constant: 16),
            lyricsTableView.trailingAnchor.constraint(equalTo: lyricsContainer.trailingAnchor, constant: -16),
            lyricsTableView.bottomAnchor.constraint(equalTo: lyricsContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupStyles() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.tintColor = .systemCyan
        segmentControl.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        currentChordCard.backgroundColor = UIColor(white: 0.08, alpha: 0.6)
        currentChordCard.layer.cornerRadius = 18
        currentChordCard.layer.borderWidth = 1.0
        currentChordCard.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        
        currentChordTitle.text = "ACTIVE CHORD ESTIMATION"
        currentChordTitle.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        currentChordTitle.textColor = UIColor.systemGreen.withAlphaComponent(0.7)
        
        currentChordLabel.text = "N"
        currentChordLabel.font = UIFont.systemFont(ofSize: 48, weight: .black)
        currentChordLabel.textColor = .systemGreen
        
        currentChordLabel.layer.shadowColor = UIColor.systemGreen.cgColor
        currentChordLabel.layer.shadowRadius = 8.0
        currentChordLabel.layer.shadowOpacity = 0.8
        currentChordLabel.layer.shadowOffset = .zero
        
        chordRootLabel.text = "Initializing CRNN classification..."
        chordRootLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        chordRootLabel.textColor = .lightGray
        
        teleprompterTitle.text = "REAL-TIME CHORD PROGRESSION CHRONOLOGY"
        teleprompterTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        teleprompterTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        metronomeTitle.text = "TEMPO DETECTOR & BEAT TRACKER"
        metronomeTitle.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        metronomeTitle.textColor = UIColor.systemCyan.withAlphaComponent(0.9)
        
        bpmLabel.text = "120.0 BPM"
        bpmLabel.font = UIFont.monospacedSystemFont(ofSize: 22, weight: .black)
        bpmLabel.textColor = .white
        
        pulseCircle.layer.cornerRadius = 90
        pulseCircle.layer.borderWidth = 3.0
        pulseCircle.layer.borderColor = UIColor.systemCyan.withAlphaComponent(0.4).cgColor
        pulseCircle.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.04)
        
        downbeatIndicator.layer.cornerRadius = 12
        downbeatIndicator.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        downbeatIndicator.layer.borderWidth = 1.0
        downbeatIndicator.layer.borderColor = UIColor.systemRed.cgColor
        
        beatIndicatorsStack.axis = .horizontal
        beatIndicatorsStack.spacing = 12
        beatIndicatorsStack.distribution = .fillEqually
        
        for _ in 0..<4 {
            let light = UIView()
            light.layer.cornerRadius = 4
            light.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
            beatIndicatorsStack.addArrangedSubview(light)
            beatIndicatorLights.append(light)
        }
    }
    
    private func setupTables() {
        for table in [chordsTableView, lyricsTableView] {
            table.backgroundColor = .clear
            table.separatorStyle = .none
            table.dataSource = self
            table.delegate = self
            table.showsVerticalScrollIndicator = false
            table.layer.cornerRadius = 16
            table.layer.borderWidth = 0.5
            table.layer.borderColor = UIColor(white: 0.2, alpha: 0.2).cgColor
            table.backgroundColor = UIColor(white: 0.08, alpha: 0.3)
        }
    }
    
    @objc private func segmentChanged() {
        showSegment(index: segmentControl.selectedSegmentIndex)
    }
    
    private func showSegment(index: Int) {
        chordsContainer.isHidden = index != 0
        beatContainer.isHidden = index != 1
        lyricsContainer.isHidden = index != 2
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func audioUpdated() {
        guard let mainTabBar = self.tabBarController as? MainViewController, isViewLoaded else { return }
        
        chordsList = mainTabBar.chordSegments
        beatsList = mainTabBar.beatResult?.beats ?? []
        downbeatsList = mainTabBar.beatResult?.downbeats ?? []
        tempoBPM = mainTabBar.beatResult?.tempo ?? 120.0
        lyricLines = mainTabBar.lyricsManager.lines
        
        bpmLabel.text = String(format: "%.1f BPM", tempoBPM)
        
        activeChordIndex = -1
        activeLyricIndex = -1
        lastBeatIndex = -1
        currentChordLabel.text = "N"
        chordRootLabel.text = chordsList.isEmpty ? "No active song chord analytical model." : "CRNN Model Loaded. Ready to Track."
        
        chordsTableView.reloadData()
        lyricsTableView.reloadData()
        
        for light in beatIndicatorLights {
            light.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
            light.transform = .identity
        }
        pulseCircle.transform = .identity
        pulseCircle.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.04)
        downbeatIndicator.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
    }
    
    func updatePlaybackPosition(time: Double) {
        guard isViewLoaded else { return }
        
        let matchedChordIdx = chordsList.firstIndex { time >= $0.startTime && time < $0.endTime } ?? -1
        if matchedChordIdx != activeChordIndex {
            activeChordIndex = matchedChordIdx
            
            if activeChordIndex >= 0 {
                let activeChord = chordsList[activeChordIndex]
                currentChordLabel.text = activeChord.name
                chordRootLabel.text = "Chord Interval: \(String(format: "%.2f", activeChord.startTime))s - \(String(format: "%.2f", activeChord.endTime))s"
                
                let indexPath = IndexPath(row: activeChordIndex, section: 0)
                chordsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                
                UIView.animate(withDuration: 0.15, animations: {
                    self.currentChordCard.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                    self.currentChordLabel.textColor = .systemGreen
                }) { _ in
                    UIView.animate(withDuration: 0.25) {
                        self.currentChordCard.transform = .identity
                    }
                }
            } else {
                currentChordLabel.text = "N"
                chordRootLabel.text = "No segment detected."
            }
        }
        
        let matchedBeatIdx = beatsList.firstIndex { time >= $0.time && time < $0.time + 0.15 } ?? -1
        if matchedBeatIdx != -1 && matchedBeatIdx != lastBeatIndex {
            lastBeatIndex = matchedBeatIdx
            let beat = beatsList[matchedBeatIdx]
            
            let isDownbeat = downbeatsList.contains { abs($0 - beat.time) < 0.15 }
            
            UIView.animate(withDuration: 0.08, animations: {
                let scale: CGFloat = isDownbeat ? 1.15 : 1.08
                self.pulseCircle.transform = CGAffineTransform(scaleX: scale, y: scale)
                self.pulseCircle.backgroundColor = isDownbeat ? UIColor.systemRed.withAlphaComponent(0.2) : UIColor.systemCyan.withAlphaComponent(0.18)
                
                if isDownbeat {
                    self.downbeatIndicator.backgroundColor = .systemRed
                    self.downbeatIndicator.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                }
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.pulseCircle.transform = .identity
                    self.pulseCircle.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.04)
                    
                    if isDownbeat {
                        self.downbeatIndicator.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
                        self.downbeatIndicator.transform = .identity
                    }
                }
            }
            
            let lightIndex = beat.index % 4
            for (i, light) in beatIndicatorLights.enumerated() {
                if i == lightIndex {
                    UIView.animate(withDuration: 0.05) {
                        light.backgroundColor = isDownbeat ? .systemRed : .systemCyan
                        light.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }
                } else {
                    UIView.animate(withDuration: 0.2) {
                        light.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
                        light.transform = .identity
                    }
                }
            }
        }
        
        let matchedLyricIdx = lyricLines.firstIndex { time >= $0.startTime && time < $0.endTime } ?? -1
        if matchedLyricIdx != activeLyricIndex {
            activeLyricIndex = matchedLyricIdx
            lyricsTableView.reloadData()
            
            if activeLyricIndex >= 0 {
                let indexPath = IndexPath(row: activeLyricIndex, section: 0)
                lyricsTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
        }
    }
    
    // MARK: - UITableView Datasource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == chordsTableView {
            return chordsList.count
        } else {
            return lyricLines.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "AnalyzerCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
            cell?.backgroundColor = .clear
            cell?.selectionStyle = .none
        }
        
        if tableView == chordsTableView {
            let chord = chordsList[indexPath.row]
            cell?.textLabel?.text = chord.name
            cell?.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            cell?.textLabel?.textColor = .white
            
            cell?.detailTextLabel?.text = "Time: \(String(format: "%.1f", chord.startTime))s - \(String(format: "%.1f", chord.endTime))s"
            cell?.detailTextLabel?.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .medium)
            cell?.detailTextLabel?.textColor = .lightGray
            
            let isActive = indexPath.row == activeChordIndex
            cell?.textLabel?.textColor = isActive ? .systemGreen : .white
            cell?.contentView.backgroundColor = isActive ? UIColor.systemGreen.withAlphaComponent(0.08) : .clear
        } else {
            let lyric = lyricLines[indexPath.row]
            cell?.textLabel?.text = lyric.text
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            cell?.textLabel?.textAlignment = .center
            cell?.textLabel?.numberOfLines = 0
            cell?.detailTextLabel?.text = nil
            
            let isActive = indexPath.row == activeLyricIndex
            cell?.textLabel?.textColor = isActive ? .white : UIColor.white.withAlphaComponent(0.25)
            cell?.textLabel?.font = isActive ? UIFont.systemFont(ofSize: 20, weight: .black) : UIFont.systemFont(ofSize: 15, weight: .bold)
            cell?.contentView.backgroundColor = isActive ? UIColor.systemCyan.withAlphaComponent(0.06) : .clear
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == chordsTableView {
            return 54
        } else {
            return 60
        }
    }
}
