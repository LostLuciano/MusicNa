import UIKit

/// Result screen - shows generated stems
public class ResultViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let stemsStackView = UIStackView()
    private let actionStackView = UIStackView()
    
    private let mixerButton = PurpleGlowButton()
    private let analyzerButton = PurpleGlowButton()
    private let exportButton = PurpleGlowButton()
    private let saveButton = PurpleGlowButton()
    
    private let audioEngine = AudioEngineManager()
    private let projectStore = ProjectStore.shared
    
    public var project: StemProject?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStems()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Pemisahan Selesai", subtitle: "6 Stem Dihasilkan")
        
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
        
        // Title
        titleLabel.text = project?.name ?? "Untitled"
        titleLabel.font = Typography.heading2
        titleLabel.textColor = StudioColors.textPrimary
        contentView.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])
        
        // Stems stack
        stemsStackView.axis = .vertical
        stemsStackView.spacing = 12
        contentView.addSubview(stemsStackView)
        
        stemsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stemsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stemsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stemsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16)
        ])
        
        // Setup stem buttons
        let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
        for stemName in stemNames {
            let button = createStemButton(stemName: stemName)
            stemsStackView.addArrangedSubview(button)
        }
        
        // Action buttons
        actionStackView.axis = .vertical
        actionStackView.spacing = 12
        contentView.addSubview(actionStackView)
        
        actionStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionStackView.topAnchor.constraint(equalTo: stemsStackView.bottomAnchor, constant: 24),
            actionStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Mixer button
        mixerButton.setTitle("Open Studio Mixer", font: Typography.labelLarge)
        mixerButton.addTarget(self, action: #selector(mixerTapped), for: .touchUpInside)
        actionStackView.addArrangedSubview(mixerButton)
        mixerButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        // Analyzer button
        analyzerButton.setTitle("View AI Analyzer", font: Typography.labelLarge)
        analyzerButton.addTarget(self, action: #selector(analyzerTapped), for: .touchUpInside)
        actionStackView.addArrangedSubview(analyzerButton)
        analyzerButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        // Export button
        exportButton.setTitle("Export Stems", font: Typography.labelLarge)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        actionStackView.addArrangedSubview(exportButton)
        exportButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        // Save button
        saveButton.setTitle("Save Project", font: Typography.labelLarge)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        actionStackView.addArrangedSubview(saveButton)
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    private func createStemButton(stemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = stemName.hashValue
        button.addTarget(self, action: #selector(stemTapped(_:)), for: .touchUpInside)
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = StudioColors.stemColor(for: stemName)
        config.baseForegroundColor = UIColor.white
        config.image = UIImage(systemName: "play.circle.fill")
        config.imagePadding = 12
        config.title = stemName.capitalized
        config.titleAlignment = .leading
        
        button.configuration = config
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return button
    }
    
    private func loadStems() {
        guard let project = project else { return }
        
        do {
            try audioEngine.loadStemFiles(project.stemURLs)
            Logger.shared.info("Loaded \(project.stemURLs.count) stems")
        } catch {
            Logger.shared.error("Failed to load stems: \(error.localizedDescription)")
        }
    }
    
    @objc private func stemTapped(_ sender: UIButton) {
        // Play stem preview
        Task {
            do {
                try audioEngine.play()
            } catch {
                Logger.shared.error("Failed to play: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func mixerTapped() {
        let vc = MixerViewController()
        vc.project = project
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func analyzerTapped() {
        let vc = AnalyzerViewController()
        vc.project = project
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func exportTapped() {
        showAlert(title: "Export", message: "Export functionality coming soon")
    }
    
    @objc private func saveTapped() {
        guard var project = project else { return }
        
        do {
            project.updatedAt = Date()
            try projectStore.saveProject(project)
            showAlert(title: "Success", message: "Project saved successfully")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
