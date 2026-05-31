import UIKit

/// Home screen - main entry point with tools and model status
public class HomeViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // New project card
    private let newProjectCard = GlassCardView()
    private let newProjectButton = PurpleGlowButton()
    
    // Import buttons
    private let importAudioButton = PurpleGlowButton()
    private let importVideoButton = PurpleGlowButton()
    
    // Tools grid
    private let toolsStackView = UIStackView()
    private var toolButtons: [UIButton] = []
    
    // Model status
    private let modelStatusCard = GlassCardView()
    private let stemModelStatus = UILabel()
    private let chordModelStatus = UILabel()
    private let beatModelStatus = UILabel()
    
    // Managers
    private let fileImporter = FileImportManager.shared
    private let projectStore = ProjectStore.shared
    private let modelManager = ModelManager.shared
    private let demoManager = DemoDataManager.shared
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateModelStatus()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateModelStatus()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Studio", subtitle: "AI Audio · Stem · Chord")
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupNewProjectCard()
        setupImportButtons()
        setupToolsGrid()
        setupModelStatus()
    }
    
    private func setupNewProjectCard() {
        newProjectCard.setupGlassCard()
        contentView.addSubview(newProjectCard)
        
        newProjectCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newProjectCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            newProjectCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            newProjectCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            newProjectCard.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Title
        titleLabel.text = "Mulai Proyek Baru"
        titleLabel.font = Typography.heading2
        titleLabel.textColor = StudioColors.textPrimary
        newProjectCard.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: newProjectCard.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: newProjectCard.topAnchor, constant: 16)
        ])
        
        // Subtitle
        subtitleLabel.text = "Impor audio atau pilih dari demo"
        subtitleLabel.font = Typography.bodySmall
        subtitleLabel.textColor = StudioColors.textSecondary
        newProjectCard.addSubview(subtitleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: newProjectCard.leadingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
        
        // Button
        newProjectButton.setTitle("Mulai", font: Typography.labelLarge)
        newProjectButton.addTarget(self, action: #selector(newProjectTapped), for: .touchUpInside)
        newProjectCard.addSubview(newProjectButton)
        
        newProjectButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newProjectButton.trailingAnchor.constraint(equalTo: newProjectCard.trailingAnchor, constant: -16),
            newProjectButton.centerYAnchor.constraint(equalTo: newProjectCard.centerYAnchor),
            newProjectButton.widthAnchor.constraint(equalToConstant: 100),
            newProjectButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupImportButtons() {
        let importStackView = UIStackView()
        importStackView.axis = .horizontal
        importStackView.distribution = .fillEqually
        importStackView.spacing = 12
        contentView.addSubview(importStackView)
        
        importStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            importStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            importStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            importStackView.topAnchor.constraint(equalTo: newProjectCard.bottomAnchor, constant: 16),
            importStackView.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // Import audio
        importAudioButton.setTitle("Impor Audio", font: Typography.labelMedium)
        importAudioButton.addTarget(self, action: #selector(importAudioTapped), for: .touchUpInside)
        importStackView.addArrangedSubview(importAudioButton)
        
        // Import video
        importVideoButton.setTitle("Impor Video", font: Typography.labelMedium)
        importVideoButton.addTarget(self, action: #selector(importVideoTapped), for: .touchUpInside)
        importStackView.addArrangedSubview(importVideoButton)
    }
    
    private func setupToolsGrid() {
        let toolsLabel = UILabel()
        toolsLabel.text = "TOOLS"
        toolsLabel.font = Typography.labelSmall
        toolsLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(toolsLabel)
        
        toolsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            toolsLabel.topAnchor.constraint(equalTo: importAudioButton.bottomAnchor, constant: 24)
        ])
        
        // Grid
        toolsStackView.axis = .vertical
        toolsStackView.spacing = 12
        contentView.addSubview(toolsStackView)
        
        toolsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            toolsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toolsStackView.topAnchor.constraint(equalTo: toolsLabel.bottomAnchor, constant: 12)
        ])
        
        let tools = [
            ("Stem Mixer", "waveform.circle"),
            ("Chord Viewer", "music.note"),
            ("Tempo & Beat", "metronome"),
            ("Rekam Audio", "mic.circle"),
            ("Rekam Video", "video.circle"),
            ("Library", "books.vertical")
        ]
        
        for (index, (title, icon)) in tools.enumerated() {
            let button = createToolButton(title: title, icon: icon, tag: index)
            toolsStackView.addArrangedSubview(button)
            toolButtons.append(button)
        }
    }
    
    private func createToolButton(title: String, icon: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = tag
        button.addTarget(self, action: #selector(toolTapped(_:)), for: .touchUpInside)
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = StudioColors.glassLight
        config.baseForegroundColor = StudioColors.purpleAccent
        config.image = UIImage(systemName: icon)
        config.imagePadding = 12
        config.title = title
        config.titleAlignment = .leading
        
        button.configuration = config
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.layer.borderColor = StudioColors.glassBorder.cgColor
        button.layer.borderWidth = 1.0
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return button
    }
    
    private func setupModelStatus() {
        let statusLabel = UILabel()
        statusLabel.text = "STATUS MODEL AI"
        statusLabel.font = Typography.labelSmall
        statusLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: toolsStackView.bottomAnchor, constant: 24)
        ])
        
        // Status card
        modelStatusCard.setupGlassCard()
        contentView.addSubview(modelStatusCard)
        
        modelStatusCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modelStatusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            modelStatusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            modelStatusCard.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            modelStatusCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Status items
        let statusStackView = UIStackView()
        statusStackView.axis = .vertical
        statusStackView.spacing = 12
        modelStatusCard.addSubview(statusStackView)
        
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusStackView.leadingAnchor.constraint(equalTo: modelStatusCard.leadingAnchor, constant: 16),
            statusStackView.trailingAnchor.constraint(equalTo: modelStatusCard.trailingAnchor, constant: -16),
            statusStackView.topAnchor.constraint(equalTo: modelStatusCard.topAnchor, constant: 16),
            statusStackView.bottomAnchor.constraint(equalTo: modelStatusCard.bottomAnchor, constant: -16)
        ])
        
        // Stem model
        stemModelStatus.font = Typography.labelMedium
        stemModelStatus.textColor = StudioColors.textPrimary
        statusStackView.addArrangedSubview(stemModelStatus)
        
        // Chord model
        chordModelStatus.font = Typography.labelMedium
        chordModelStatus.textColor = StudioColors.textPrimary
        statusStackView.addArrangedSubview(chordModelStatus)
        
        // Beat model
        beatModelStatus.font = Typography.labelMedium
        beatModelStatus.textColor = StudioColors.textPrimary
        statusStackView.addArrangedSubview(beatModelStatus)
    }
    
    private func updateModelStatus() {
        let models = modelManager.getAvailableModels()
        
        // Stem model
        let stemModel = models.first { $0.type == .stemSeparation }
        stemModelStatus.text = "Stem Model: \(stemModel?.isLoaded == true ? "✅ Ready" : "❌ Missing")"
        stemModelStatus.textColor = stemModel?.isLoaded == true ? StudioColors.statusSuccess : StudioColors.statusError
        
        // Chord model
        let chordModel = models.first { $0.type == .chordDetection }
        chordModelStatus.text = "Chord Model: \(chordModel?.isLoaded == true ? "✅ Ready" : "❌ Missing")"
        chordModelStatus.textColor = chordModel?.isLoaded == true ? StudioColors.statusSuccess : StudioColors.statusError
        
        // Beat model
        let beatModel = models.first { $0.type == .beatDetection }
        beatModelStatus.text = "Beat Model: \(beatModel?.isLoaded == true ? "✅ Ready" : "❌ Missing")"
        beatModelStatus.textColor = beatModel?.isLoaded == true ? StudioColors.statusSuccess : StudioColors.statusError
    }
    
    // MARK: - Actions
    
    @objc private func newProjectTapped() {
        let vc = ImportSourceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func importAudioTapped() {
        let vc = ImportSourceViewController()
        vc.importMode = .audio
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func importVideoTapped() {
        let vc = ImportSourceViewController()
        vc.importMode = .video
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func toolTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0: // Stem Mixer
            openStemMixer()
        case 1: // Chord Viewer
            openChordViewer()
        case 2: // Tempo & Beat
            openBeatAnalyzer()
        case 3: // Rekam Audio
            openRecording()
        case 4: // Rekam Video
            openVideoRecording()
        case 5: // Library
            openLibrary()
        default:
            break
        }
    }
    
    private func openStemMixer() {
        // Check if project exists
        do {
            let projects = try projectStore.loadAllProjects()
            if projects.isEmpty {
                showAlert(title: "Tidak Ada Proyek", message: "Pilih atau impor audio dulu.")
                return
            }
            
            let vc = MixerViewController()
            vc.project = projects.first
            navigationController?.pushViewController(vc, animated: true)
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func openChordViewer() {
        let vc = AnalyzerViewController()
        vc.selectedTab = 0 // Chords tab
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openBeatAnalyzer() {
        let vc = AnalyzerViewController()
        vc.selectedTab = 1 // Beat tab
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openRecording() {
        let vc = RecordingViewController()
        vc.recordingMode = .audioOnly
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openVideoRecording() {
        let vc = RecordingViewController()
        vc.recordingMode = .video
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openLibrary() {
        let vc = LibraryViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
