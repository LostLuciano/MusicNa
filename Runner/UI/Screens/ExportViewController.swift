import UIKit

/// Export screen - export stems and mixes in various formats
public class ExportViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Project info card
    private let projectCard = GlassCardView()
    private let projectNameLabel = UILabel()
    private let projectDurationLabel = UILabel()
    private let projectSizeLabel = UILabel()
    
    // Export options
    private let optionsStackView = UIStackView()
    
    // Format selection
    private let formatLabel = UILabel()
    private let formatSegmentedControl = UISegmentedControl(items: ["M4A", "WAV", "FLAC", "MP3"])
    
    // Quality selection
    private let qualityLabel = UILabel()
    private let qualitySegmentedControl = UISegmentedControl(items: ["Low", "Medium", "High", "Very High"])
    
    // Export type selection
    private let typeLabel = UILabel()
    private let stereoMixButton = UIButton(type: .system)
    private let individualStemsButton = UIButton(type: .system)
    private let projectExportButton = UIButton(type: .system)
    
    // Progress
    private let progressCard = GlassCardView()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let cancelButton = UIButton(type: .system)
    
    // Action buttons
    private let exportButton = PurpleGlowButton()
    private let shareButton = UIButton(type: .system)
    
    // Managers
    private let exportManager = ExportManager.shared
    private let projectStore = ProjectStore.shared
    
    public var project: StemProject?
    private var selectedFormat: ExportManager.ExportFormat = .m4a
    private var selectedQuality: ExportManager.AudioQuality = .high
    private var selectedType: ExportType = .stereoMix
    
    private enum ExportType {
        case stereoMix
        case individualStems
        case projectExport
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProject()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exportManager.cleanupTempFiles()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Export", subtitle: "Save Your Mix")
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        // Title
        titleLabel.text = "Export Options"
        titleLabel.font = StudioTheme.typography.heading
        titleLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        subtitleLabel.text = "Choose format and quality for your export"
        subtitleLabel.font = StudioTheme.typography.body
        subtitleLabel.textColor = StudioTheme.colors.textSecondary
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // Project info card
        projectCard.layer.cornerRadius = 16
        contentView.addSubview(projectCard)
        projectCard.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
        
        projectNameLabel.font = StudioTheme.typography.body
        projectNameLabel.textColor = StudioTheme.colors.textPrimary
        projectCard.addSubview(projectNameLabel)
        projectNameLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
        }
        
        projectDurationLabel.font = StudioTheme.typography.label
        projectDurationLabel.textColor = StudioTheme.colors.textSecondary
        projectCard.addSubview(projectDurationLabel)
        projectDurationLabel.snp.makeConstraints { make in
            make.top.equalTo(projectNameLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
        }
        
        projectSizeLabel.font = StudioTheme.typography.label
        projectSizeLabel.textColor = StudioTheme.colors.textSecondary
        projectCard.addSubview(projectSizeLabel)
        projectSizeLabel.snp.makeConstraints { make in
            make.top.equalTo(projectDurationLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
        }
        
        // Format selection
        formatLabel.text = "Format"
        formatLabel.font = StudioTheme.typography.body
        formatLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(formatLabel)
        formatLabel.snp.makeConstraints { make in
            make.top.equalTo(projectCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        formatSegmentedControl.selectedSegmentIndex = 0
        formatSegmentedControl.addTarget(self, action: #selector(formatChanged), for: .valueChanged)
        contentView.addSubview(formatSegmentedControl)
        formatSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(formatLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        // Quality selection
        qualityLabel.text = "Quality"
        qualityLabel.font = StudioTheme.typography.body
        qualityLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(qualityLabel)
        qualityLabel.snp.makeConstraints { make in
            make.top.equalTo(formatSegmentedControl.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        qualitySegmentedControl.selectedSegmentIndex = 2
        qualitySegmentedControl.addTarget(self, action: #selector(qualityChanged), for: .valueChanged)
        contentView.addSubview(qualitySegmentedControl)
        qualitySegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(qualityLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        // Export type selection
        typeLabel.text = "Export Type"
        typeLabel.font = StudioTheme.typography.body
        typeLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(typeLabel)
        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(qualitySegmentedControl.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // Stereo mix button
        stereoMixButton.setTitle("🎵 Stereo Mix", for: .normal)
        stereoMixButton.titleLabel?.font = StudioTheme.typography.body
        stereoMixButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        stereoMixButton.addTarget(self, action: #selector(selectStereoMix), for: .touchUpInside)
        contentView.addSubview(stereoMixButton)
        stereoMixButton.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Individual stems button
        individualStemsButton.setTitle("🎸 Individual Stems", for: .normal)
        individualStemsButton.titleLabel?.font = StudioTheme.typography.body
        individualStemsButton.setTitleColor(StudioTheme.colors.textSecondary, for: .normal)
        individualStemsButton.addTarget(self, action: #selector(selectIndividualStems), for: .touchUpInside)
        contentView.addSubview(individualStemsButton)
        individualStemsButton.snp.makeConstraints { make in
            make.top.equalTo(stereoMixButton.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Project export button
        projectExportButton.setTitle("📦 Full Project", for: .normal)
        projectExportButton.titleLabel?.font = StudioTheme.typography.body
        projectExportButton.setTitleColor(StudioTheme.colors.textSecondary, for: .normal)
        projectExportButton.addTarget(self, action: #selector(selectProjectExport), for: .touchUpInside)
        contentView.addSubview(projectExportButton)
        projectExportButton.snp.makeConstraints { make in
            make.top.equalTo(individualStemsButton.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Progress card (hidden initially)
        progressCard.layer.cornerRadius = 16
        progressCard.isHidden = true
        contentView.addSubview(progressCard)
        progressCard.snp.makeConstraints { make in
            make.top.equalTo(projectExportButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
        
        progressLabel.text = "Exporting..."
        progressLabel.font = StudioTheme.typography.body
        progressLabel.textColor = StudioTheme.colors.textPrimary
        progressCard.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
        }
        
        progressView.progressTintColor = StudioTheme.colors.accentPurple
        progressView.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        progressCard.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(4)
        }
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelExport), for: .touchUpInside)
        progressCard.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        // Export button
        exportButton.setTitle("Export", for: .normal)
        exportButton.addTarget(self, action: #selector(startExport), for: .touchUpInside)
        contentView.addSubview(exportButton)
        exportButton.snp.makeConstraints { make in
            make.top.equalTo(progressCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        
        // Share button
        shareButton.setTitle("Share", for: .normal)
        shareButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        shareButton.addTarget(self, action: #selector(shareExport), for: .touchUpInside)
        contentView.addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.top.equalTo(exportButton.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    private func loadProject() {
        guard let project = project else {
            projectNameLabel.text = "No project selected"
            return
        }
        
        projectNameLabel.text = project.name
        projectDurationLabel.text = "Duration: \(formatDuration(project.duration))"
        
        let estimatedSize = Int64(project.duration * 44100 * 4)
        projectSizeLabel.text = "Est. Size: \(ExportManager.formatFileSize(estimatedSize))"
    }
    
    @objc private func formatChanged() {
        let formats: [ExportManager.ExportFormat] = [.m4a, .wav, .flac, .mp3]
        selectedFormat = formats[formatSegmentedControl.selectedSegmentIndex]
        Logger.shared.debug("Format changed to: \(selectedFormat.rawValue)")
    }
    
    @objc private func qualityChanged() {
        let qualities: [ExportManager.AudioQuality] = [.low, .medium, .high, .veryHigh]
        selectedQuality = qualities[qualitySegmentedControl.selectedSegmentIndex]
        Logger.shared.debug("Quality changed to: \(selectedQuality.rawValue)")
    }
    
    @objc private func selectStereoMix() {
        selectedType = .stereoMix
        updateTypeSelection()
    }
    
    @objc private func selectIndividualStems() {
        selectedType = .individualStems
        updateTypeSelection()
    }
    
    @objc private func selectProjectExport() {
        selectedType = .projectExport
        updateTypeSelection()
    }
    
    private func updateTypeSelection() {
        let accentColor = StudioTheme.colors.accentPurple
        let secondaryColor = StudioTheme.colors.textSecondary
        
        stereoMixButton.setTitleColor(
            selectedType == .stereoMix ? accentColor : secondaryColor,
            for: .normal
        )
        individualStemsButton.setTitleColor(
            selectedType == .individualStems ? accentColor : secondaryColor,
            for: .normal
        )
        projectExportButton.setTitleColor(
            selectedType == .projectExport ? accentColor : secondaryColor,
            for: .normal
        )
    }
    
    @objc private func startExport() {
        guard let project = project else {
            showAlert(title: "Error", message: "No project selected")
            return
        }
        
        progressCard.isHidden = false
        exportButton.isEnabled = false
        
        let progress: (Float) -> Void = { [weak self] value in
            DispatchQueue.main.async {
                self?.progressView.progress = value
                self?.progressLabel.text = "Exporting... \(Int(value * 100))%"
            }
        }
        
        let completion: (Result<URL, ExportManager.ExportError>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                self?.progressCard.isHidden = true
                self?.exportButton.isEnabled = true
                
                switch result {
                case .success(let url):
                    self?.showAlert(
                        title: "Success",
                        message: "Export saved to: \(url.lastPathComponent)"
                    )
                    Logger.shared.info("Export successful: \(url.lastPathComponent)")
                    
                case .failure(let error):
                    self?.showAlert(title: "Export Failed", message: error.localizedDescription)
                    Logger.shared.error("Export failed: \(error)")
                }
            }
        }
        
        switch selectedType {
        case .stereoMix:
            exportManager.exportStereoMix(
                from: project,
                format: selectedFormat,
                quality: selectedQuality,
                progress: progress,
                completion: completion
            )
            
        case .individualStems:
            exportManager.exportIndividualStems(
                from: project,
                format: selectedFormat,
                quality: selectedQuality,
                progress: progress,
                completion: completion
            )
            
        case .projectExport:
            exportManager.exportProject(
                project,
                format: selectedFormat,
                progress: progress,
                completion: completion
            )
        }
    }
    
    @objc private func cancelExport() {
        exportManager.cancelExport()
        progressCard.isHidden = true
        exportButton.isEnabled = true
    }
    
    @objc private func shareExport() {
        showAlert(title: "Share", message: "Share functionality coming soon")
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
