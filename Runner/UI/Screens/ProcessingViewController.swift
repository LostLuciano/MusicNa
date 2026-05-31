import UIKit

/// Processing screen - shows real stem separation progress
public class ProcessingViewController: UIViewController {
    
    private let cardView = GlassCardView()
    private let titleLabel = UILabel()
    private let progressRing = ProcessingRingView()
    private let stagesStackView = UIStackView()
    private let infoLabel = UILabel()
    private let cancelButton = PurpleGlowButton()
    
    private let separatorWrapper = CoreMLStemSeparatorWrapper.shared
    private let projectStore = ProjectStore.shared
    private let performanceGuard = PerformanceGuard.shared
    
    public var project: StemProject?
    private var isProcessing = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startProcessing()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Pemisahan Stem", subtitle: "Proses berlangsung...")
        navigationItem.hidesBackButton = true
        
        // Card
        cardView.setupGlassCard()
        view.addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
        
        // Title
        titleLabel.font = Typography.heading2
        titleLabel.textColor = StudioColors.textPrimary
        cardView.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16)
        ])
        
        // Progress ring
        progressRing.progressColor = StudioColors.purpleAccent
        cardView.addSubview(progressRing)
        
        progressRing.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressRing.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            progressRing.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            progressRing.widthAnchor.constraint(equalToConstant: 120),
            progressRing.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Stages stack
        stagesStackView.axis = .vertical
        stagesStackView.spacing = 8
        cardView.addSubview(stagesStackView)
        
        stagesStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stagesStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stagesStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stagesStackView.topAnchor.constraint(equalTo: progressRing.bottomAnchor, constant: 20)
        ])
        
        // Setup stages
        let stages = ["Decode Audio", "STFT Transform", "AI Inference", "Reconstruction", "Export Stems"]
        for stage in stages {
            let stageRow = ProcessingStageRowView()
            stageRow.stageName = stage
            stageRow.status = .pending
            stagesStackView.addArrangedSubview(stageRow)
        }
        
        // Info label
        infoLabel.font = Typography.bodySmall
        infoLabel.textColor = StudioColors.textSecondary
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        cardView.addSubview(infoLabel)
        
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            infoLabel.topAnchor.constraint(equalTo: stagesStackView.bottomAnchor, constant: 16)
        ])
        
        // Cancel button
        cancelButton.setTitle("Batalkan", font: Typography.labelLarge)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cardView.addSubview(cancelButton)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 150),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func startProcessing() {
        guard let project = project, let audioURL = project.originalAudioURL else {
            showError("Project atau audio tidak ditemukan")
            return
        }
        
        isProcessing = true
        titleLabel.text = project.name
        
        Task {
            do {
                let stems = try await separatorWrapper.separate(
                    audioURL: audioURL,
                    processingMode: "Neural Engine",
                    modelQuality: "Model Ringan",
                    onProgress: { [weak self] message, progress in
                        DispatchQueue.main.async {
                            self?.updateProgress(message: message, progress: progress)
                        }
                    }
                )
                
                // Update project
                var updatedProject = project
                updatedProject.stemURLs = stems
                try projectStore.saveProject(updatedProject)
                
                // Navigate to result
                DispatchQueue.main.async {
                    let vc = ResultViewController()
                    vc.project = updatedProject
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func updateProgress(message: String, progress: Double) {
        progressRing.progress = CGFloat(progress)
        infoLabel.text = message
        
        // Update stage status
        let stageIndex = getStageIndex(from: message)
        for (index, stageView) in stagesStackView.arrangedSubviews.enumerated() {
            guard let stage = stageView as? ProcessingStageRowView else { continue }
            
            if index < stageIndex {
                stage.status = .completed
            } else if index == stageIndex {
                stage.status = .running
            } else {
                stage.status = .pending
            }
        }
    }
    
    private func getStageIndex(from message: String) -> Int {
        if message.contains("Decode") { return 0 }
        if message.contains("STFT") { return 1 }
        if message.contains("Inference") { return 2 }
        if message.contains("Reconstruction") { return 3 }
        if message.contains("Export") { return 4 }
        return 0
    }
    
    @objc private func cancelTapped() {
        isProcessing = false
        processingGate.cancelQueue()
        navigationController?.popViewController(animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// Add missing import
private let processingGate = ProcessingGate.shared
