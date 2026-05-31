import UIKit

/// Import source selection screen
public class ImportSourceViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let importAudioButton = PurpleGlowButton()
    private let importVideoButton = PurpleGlowButton()
    private let browseFilesButton = PurpleGlowButton()
    
    private let recentFilesLabel = UILabel()
    private let recentFilesStackView = UIStackView()
    
    private let formatsLabel = UILabel()
    private let formatsTextView = UITextView()
    
    private let fileImporter = FileImportManager.shared
    private let projectStore = ProjectStore.shared
    
    public var importMode: ImportMode = .all
    
    public enum ImportMode {
        case all
        case audio
        case video
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Impor Audio / Video", subtitle: "Pilih sumber file")
        
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
        
        setupImportButtons()
        setupRecentFiles()
        setupFormats()
    }
    
    private func setupImportButtons() {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        contentView.addSubview(buttonStackView)
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])
        
        // Import audio
        if importMode == .all || importMode == .audio {
            importAudioButton.setTitle("Impor Audio", font: Typography.labelLarge)
            importAudioButton.addTarget(self, action: #selector(importAudioTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(importAudioButton)
            importAudioButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
        
        // Import video
        if importMode == .all || importMode == .video {
            importVideoButton.setTitle("Impor Video", font: Typography.labelLarge)
            importVideoButton.addTarget(self, action: #selector(importVideoTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(importVideoButton)
            importVideoButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
        
        // Browse files
        browseFilesButton.setTitle("Browse iPhone Files", font: Typography.labelLarge)
        browseFilesButton.addTarget(self, action: #selector(browseFilesTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(browseFilesButton)
        browseFilesButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    private func setupRecentFiles() {
        recentFilesLabel.text = "RECENT FILES"
        recentFilesLabel.font = Typography.labelSmall
        recentFilesLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(recentFilesLabel)
        
        recentFilesLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recentFilesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentFilesLabel.topAnchor.constraint(equalTo: browseFilesButton.bottomAnchor, constant: 24)
        ])
        
        // Recent files stack
        recentFilesStackView.axis = .vertical
        recentFilesStackView.spacing = 8
        contentView.addSubview(recentFilesStackView)
        
        recentFilesStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recentFilesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentFilesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recentFilesStackView.topAnchor.constraint(equalTo: recentFilesLabel.bottomAnchor, constant: 12)
        ])
        
        // Load recent files
        do {
            let projects = try projectStore.loadAllProjects()
            for project in projects.prefix(3) {
                let button = createRecentFileButton(project: project)
                recentFilesStackView.addArrangedSubview(button)
            }
        } catch {
            Logger.shared.error("Failed to load recent files: \(error.localizedDescription)")
        }
    }
    
    private func createRecentFileButton(project: StemProject) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(recentFileTapped(_:)), for: .touchUpInside)
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "doc.audio")
        config.imagePadding = 12
        config.title = project.name
        config.baseForegroundColor = StudioColors.textSecondary
        config.titleAlignment = .leading
        
        button.configuration = config
        button.backgroundColor = StudioColors.glassDark
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    private func setupFormats() {
        formatsLabel.text = "FORMAT DIDUKUNG"
        formatsLabel.font = Typography.labelSmall
        formatsLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(formatsLabel)
        
        formatsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formatsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formatsLabel.topAnchor.constraint(equalTo: recentFilesStackView.bottomAnchor, constant: 24)
        ])
        
        // Formats text
        formatsTextView.backgroundColor = StudioColors.glassDark
        formatsTextView.textColor = StudioColors.textSecondary
        formatsTextView.font = Typography.bodySmall
        formatsTextView.isEditable = false
        formatsTextView.isScrollEnabled = false
        formatsTextView.layer.cornerRadius = 12
        formatsTextView.clipsToBounds = true
        
        let formats = """
        Audio: MP3, WAV, M4A, AAC, AIFF, FLAC, CAF
        Video: MP4, MOV
        
        Max file size: 2 GB
        Supported sample rates: 44.1 kHz, 48 kHz
        """
        formatsTextView.text = formats
        contentView.addSubview(formatsTextView)
        
        formatsTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formatsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formatsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formatsTextView.topAnchor.constraint(equalTo: formatsLabel.bottomAnchor, constant: 12),
            formatsTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            formatsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func importAudioTapped() {
        fileImporter.presentFilePicker(from: self) { [weak self] result in
            switch result {
            case .success(let url):
                self?.handleImportedFile(url, isVideo: false)
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
    
    @objc private func importVideoTapped() {
        fileImporter.presentFilePicker(from: self) { [weak self] result in
            switch result {
            case .success(let url):
                self?.handleImportedFile(url, isVideo: true)
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
    
    @objc private func browseFilesTapped() {
        fileImporter.presentFilePicker(from: self) { [weak self] result in
            switch result {
            case .success(let url):
                self?.handleImportedFile(url, isVideo: false)
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
    
    @objc private func recentFileTapped(_ sender: UIButton) {
        // Navigate to processing for recent file
        navigationController?.popViewController(animated: true)
    }
    
    private func handleImportedFile(_ url: URL, isVideo: Bool) {
        // Create project
        var project = StemProject(name: url.deletingPathExtension().lastPathComponent)
        project.originalAudioURL = url
        
        do {
            try projectStore.saveProject(project)
            
            // Navigate to processing
            let vc = ProcessingViewController()
            vc.project = project
            navigationController?.pushViewController(vc, animated: true)
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
