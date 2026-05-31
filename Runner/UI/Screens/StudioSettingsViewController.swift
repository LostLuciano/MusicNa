import UIKit

/// Settings screen - CoreML configuration, model quality, buffer settings
public class StudioSettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let modelManager = ModelManager.shared
    private let performanceGuard = PerformanceGuard.shared
    
    // Settings controls
    private var computeUnitSegment: UISegmentedControl?
    private var modelQualitySegment: UISegmentedControl?
    private var bufferSizeSlider: UISlider?
    private var sampleRateSegment: UISegmentedControl?
    private var modelStatusLabel: UILabel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Settings", subtitle: "Studio Configuration")
        
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
        
        var lastView: UIView = contentView
        
        // MARK: - Model Status Section
        
        let statusSection = createSectionLabel("MODEL STATUS")
        contentView.addSubview(statusSection)
        statusSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])
        lastView = statusSection
        
        // Model status card
        let statusCard = createStatusCard()
        contentView.addSubview(statusCard)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusCard.topAnchor.constraint(equalTo: statusSection.bottomAnchor, constant: 12),
            statusCard.heightAnchor.constraint(equalToConstant: 120)
        ])
        lastView = statusCard
        
        // MARK: - Compute Unit Section
        
        let computeSection = createSectionLabel("COMPUTE UNIT")
        contentView.addSubview(computeSection)
        computeSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            computeSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            computeSection.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24)
        ])
        
        let computeDesc = createDescriptionLabel("Select processing hardware for AI models")
        contentView.addSubview(computeDesc)
        computeDesc.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            computeDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            computeDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            computeDesc.topAnchor.constraint(equalTo: computeSection.bottomAnchor, constant: 8)
        ])
        
        let computeSegment = UISegmentedControl(items: ["Neural Engine", "GPU+CPU", "CPU Only"])
        computeSegment.selectedSegmentIndex = 0
        computeSegment.addTarget(self, action: #selector(computeUnitChanged), for: .valueChanged)
        self.computeUnitSegment = computeSegment
        
        let computeContainer = createSegmentContainer(computeSegment)
        contentView.addSubview(computeContainer)
        computeContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            computeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            computeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            computeContainer.topAnchor.constraint(equalTo: computeDesc.bottomAnchor, constant: 12),
            computeContainer.heightAnchor.constraint(equalToConstant: 48)
        ])
        lastView = computeContainer
        
        // MARK: - Model Quality Section
        
        let qualitySection = createSectionLabel("MODEL QUALITY")
        contentView.addSubview(qualitySection)
        qualitySection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            qualitySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            qualitySection.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24)
        ])
        
        let qualityDesc = createDescriptionLabel("Light = faster, Standard = better quality")
        contentView.addSubview(qualityDesc)
        qualityDesc.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            qualityDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            qualityDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            qualityDesc.topAnchor.constraint(equalTo: qualitySection.bottomAnchor, constant: 8)
        ])
        
        let qualitySegment = UISegmentedControl(items: ["Light (FP16)", "Standard (FP32)"])
        qualitySegment.selectedSegmentIndex = 0
        qualitySegment.addTarget(self, action: #selector(modelQualityChanged), for: .valueChanged)
        self.modelQualitySegment = qualitySegment
        
        let qualityContainer = createSegmentContainer(qualitySegment)
        contentView.addSubview(qualityContainer)
        qualityContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            qualityContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            qualityContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            qualityContainer.topAnchor.constraint(equalTo: qualityDesc.bottomAnchor, constant: 12),
            qualityContainer.heightAnchor.constraint(equalToConstant: 48)
        ])
        lastView = qualityContainer
        
        // MARK: - Buffer Size Section
        
        let bufferSection = createSectionLabel("BUFFER SIZE")
        contentView.addSubview(bufferSection)
        bufferSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bufferSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bufferSection.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24)
        ])
        
        let bufferDesc = createDescriptionLabel("Larger = lower latency, more CPU usage")
        contentView.addSubview(bufferDesc)
        bufferDesc.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bufferDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bufferDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bufferDesc.topAnchor.constraint(equalTo: bufferSection.bottomAnchor, constant: 8)
        ])
        
        let bufferSlider = UISlider()
        bufferSlider.minimumValue = 256
        bufferSlider.maximumValue = 4096
        bufferSlider.value = 2048
        bufferSlider.addTarget(self, action: #selector(bufferSizeChanged), for: .valueChanged)
        self.bufferSizeSlider = bufferSlider
        
        let bufferContainer = createSliderContainer(bufferSlider, label: "2048 samples")
        contentView.addSubview(bufferContainer)
        bufferContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bufferContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bufferContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bufferContainer.topAnchor.constraint(equalTo: bufferDesc.bottomAnchor, constant: 12),
            bufferContainer.heightAnchor.constraint(equalToConstant: 80)
        ])
        lastView = bufferContainer
        
        // MARK: - Sample Rate Section
        
        let sampleSection = createSectionLabel("SAMPLE RATE")
        contentView.addSubview(sampleSection)
        sampleSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sampleSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sampleSection.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24)
        ])
        
        let sampleDesc = createDescriptionLabel("Higher = better quality, more CPU usage")
        contentView.addSubview(sampleDesc)
        sampleDesc.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sampleDesc.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sampleDesc.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sampleDesc.topAnchor.constraint(equalTo: sampleSection.bottomAnchor, constant: 8)
        ])
        
        let sampleSegment = UISegmentedControl(items: ["44.1 kHz", "48 kHz"])
        sampleSegment.selectedSegmentIndex = 1
        sampleSegment.addTarget(self, action: #selector(sampleRateChanged), for: .valueChanged)
        self.sampleRateSegment = sampleSegment
        
        let sampleContainer = createSegmentContainer(sampleSegment)
        contentView.addSubview(sampleContainer)
        sampleContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sampleContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sampleContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sampleContainer.topAnchor.constraint(equalTo: sampleDesc.bottomAnchor, constant: 12),
            sampleContainer.heightAnchor.constraint(equalToConstant: 48)
        ])
        lastView = sampleContainer
        
        // MARK: - Action Buttons
        
        let resetButton = createActionButton(title: "Reset to Defaults", action: #selector(resetSettings))
        contentView.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resetButton.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24),
            resetButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        let clearCacheButton = createActionButton(title: "Clear Cache", action: #selector(clearCache), style: .destructive)
        contentView.addSubview(clearCacheButton)
        clearCacheButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clearCacheButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            clearCacheButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            clearCacheButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 12),
            clearCacheButton.heightAnchor.constraint(equalToConstant: 48),
            clearCacheButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - UI Helpers
    
    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Typography.labelSmall
        label.textColor = StudioColors.textTertiary
        return label
    }
    
    private func createDescriptionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Typography.bodySmall
        label.textColor = StudioColors.textSecondary
        label.numberOfLines = 0
        return label
    }
    
    private func createSegmentContainer(_ segment: UISegmentedControl) -> UIView {
        let container = UIView()
        container.backgroundColor = StudioColors.glassDark
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        
        segment.backgroundColor = .clear
        segment.setBackgroundImage(UIImage(), for: .normal, barMetrics: .default)
        segment.setDividerImage(UIImage(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        container.addSubview(segment)
        segment.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segment.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            segment.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            segment.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            segment.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func createSliderContainer(_ slider: UISlider, label: String) -> UIView {
        let container = UIView()
        container.backgroundColor = StudioColors.glassDark
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Buffer Size"
        titleLabel.font = Typography.labelMedium
        titleLabel.textColor = StudioColors.textPrimary
        container.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12)
        ])
        
        let valueLabel = UILabel()
        valueLabel.text = label
        valueLabel.font = Typography.labelSmall
        valueLabel.textColor = StudioColors.purpleAccent
        valueLabel.textAlignment = .right
        container.addSubview(valueLabel)
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
        
        slider.tintColor = StudioColors.purpleAccent
        container.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            slider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            slider.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
    
    private func createStatusCard() -> UIView {
        let card = UIView()
        card.backgroundColor = StudioColors.glassDark
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Model Status"
        titleLabel.font = Typography.labelMedium
        titleLabel.textColor = StudioColors.textPrimary
        card.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12)
        ])
        
        let statusLabel = UILabel()
        statusLabel.text = "Loading..."
        statusLabel.font = Typography.bodySmall
        statusLabel.textColor = StudioColors.textSecondary
        statusLabel.numberOfLines = 0
        self.modelStatusLabel = statusLabel
        card.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    private func createActionButton(title: String, action: Selector, style: UIButton.Configuration.ButtonStyle = .filled) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .white
        config.baseBackgroundColor = style == .destructive ? UIColor.systemRed : StudioColors.purpleAccent
        config.cornerStyle = .medium
        
        button.configuration = config
        return button
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load compute unit
        let computeUnitIndex = defaults.integer(forKey: "computeUnit")
        computeUnitSegment?.selectedSegmentIndex = computeUnitIndex
        
        // Load model quality
        let qualityIndex = defaults.integer(forKey: "modelQuality")
        modelQualitySegment?.selectedSegmentIndex = qualityIndex
        
        // Load buffer size
        let bufferSize = defaults.float(forKey: "bufferSize")
        if bufferSize > 0 {
            bufferSizeSlider?.value = bufferSize
        }
        
        // Load sample rate
        let sampleRateIndex = defaults.integer(forKey: "sampleRate")
        sampleRateSegment?.selectedSegmentIndex = sampleRateIndex
        
        updateModelStatus()
    }
    
    private func updateModelStatus() {
        let models = modelManager.getAvailableModels()
        let loadedCount = models.filter { $0.isLoaded }.count
        let totalMemory = modelManager.getTotalModelMemory()
        
        let memoryFormatter = ByteCountFormatter()
        memoryFormatter.countStyle = .memory
        let memoryString = memoryFormatter.string(fromByteCount: Int64(totalMemory))
        
        let status = """
        Loaded: \(loadedCount)/\(models.count) models
        Memory: \(memoryString)
        Thermal: \(performanceGuard.getThermalState())
        """
        
        modelStatusLabel?.text = status
    }
    
    @objc private func computeUnitChanged() {
        guard let index = computeUnitSegment?.selectedSegmentIndex else { return }
        UserDefaults.standard.set(index, forKey: "computeUnit")
        Logger.shared.info("Compute unit changed to index: \(index)")
    }
    
    @objc private func modelQualityChanged() {
        guard let index = modelQualitySegment?.selectedSegmentIndex else { return }
        UserDefaults.standard.set(index, forKey: "modelQuality")
        Logger.shared.info("Model quality changed to index: \(index)")
    }
    
    @objc private func bufferSizeChanged() {
        guard let value = bufferSizeSlider?.value else { return }
        UserDefaults.standard.set(value, forKey: "bufferSize")
        Logger.shared.info("Buffer size changed to: \(Int(value)) samples")
    }
    
    @objc private func sampleRateChanged() {
        guard let index = sampleRateSegment?.selectedSegmentIndex else { return }
        UserDefaults.standard.set(index, forKey: "sampleRate")
        Logger.shared.info("Sample rate changed to index: \(index)")
    }
    
    @objc private func resetSettings() {
        let alert = UIAlertController(title: "Reset Settings?", message: "This will restore all settings to defaults.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            UserDefaults.standard.removeObject(forKey: "computeUnit")
            UserDefaults.standard.removeObject(forKey: "modelQuality")
            UserDefaults.standard.removeObject(forKey: "bufferSize")
            UserDefaults.standard.removeObject(forKey: "sampleRate")
            
            self.loadSettings()
            Logger.shared.info("Settings reset to defaults")
        })
        present(alert, animated: true)
    }
    
    @objc private func clearCache() {
        let alert = UIAlertController(title: "Clear Cache?", message: "This will remove all cached audio data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            do {
                try CacheManager.shared.clearCache()
                self.updateModelStatus()
                Logger.shared.info("Cache cleared")
            } catch {
                Logger.shared.error("Failed to clear cache: \(error.localizedDescription)")
            }
        })
        present(alert, animated: true)
    }
}
