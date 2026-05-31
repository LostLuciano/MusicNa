import UIKit
import AVFoundation

/// Recording screen - audio and video recording with real-time metering
public class RecordingViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Recording mode selection
    private let modeLabel = UILabel()
    private let audioModeButton = UIButton(type: .system)
    private let videoModeButton = UIButton(type: .system)
    
    // Recording controls
    private let controlsCard = GlassCardView()
    private let recordButton = PurpleGlowButton()
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    // Time display
    private let timeLabel = UILabel()
    private let timeValueLabel = UILabel()
    
    // Level metering
    private let levelCard = GlassCardView()
    private let levelLabel = UILabel()
    private let levelMeterView = AudioLevelMeterView()
    
    // Recording info
    private let infoCard = GlassCardView()
    private let sampleRateLabel = UILabel()
    private let bitDepthLabel = UILabel()
    private let fileFormatLabel = UILabel()
    
    // Save options
    private let saveCard = GlassCardView()
    private let projectNameField = UITextField()
    private let saveButton = PurpleGlowButton()
    private let discardButton = UIButton(type: .system)
    
    // Managers
    private let audioEngine = AudioEngineManager()
    private let projectStore = ProjectStore.shared
    private let processingGate = ProcessingGate.shared
    
    private var recordingSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    private var isRecording = false
    private var isPaused = false
    private var selectedMode: RecordingMode = .audio
    
    private enum RecordingMode {
        case audio
        case video
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioSession()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRecording()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Recording", subtitle: "Capture Your Performance")
        
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
        titleLabel.text = "Recording Mode"
        titleLabel.font = StudioTheme.typography.heading
        titleLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        subtitleLabel.text = "Choose recording mode and start capturing"
        subtitleLabel.font = StudioTheme.typography.body
        subtitleLabel.textColor = StudioTheme.colors.textSecondary
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        // Mode selection
        modeLabel.text = "Select Mode"
        modeLabel.font = StudioTheme.typography.body
        modeLabel.textColor = StudioTheme.colors.textPrimary
        contentView.addSubview(modeLabel)
        modeLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
        }
        
        audioModeButton.setTitle("🎤 Audio Recording", for: .normal)
        audioModeButton.titleLabel?.font = StudioTheme.typography.body
        audioModeButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        audioModeButton.addTarget(self, action: #selector(selectAudioMode), for: .touchUpInside)
        contentView.addSubview(audioModeButton)
        audioModeButton.snp.makeConstraints { make in
            make.top.equalTo(modeLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        videoModeButton.setTitle("🎥 Video Recording", for: .normal)
        videoModeButton.titleLabel?.font = StudioTheme.typography.body
        videoModeButton.setTitleColor(StudioTheme.colors.textSecondary, for: .normal)
        videoModeButton.addTarget(self, action: #selector(selectVideoMode), for: .touchUpInside)
        contentView.addSubview(videoModeButton)
        videoModeButton.snp.makeConstraints { make in
            make.top.equalTo(audioModeButton.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Controls card
        controlsCard.layer.cornerRadius = 16
        contentView.addSubview(controlsCard)
        controlsCard.snp.makeConstraints { make in
            make.top.equalTo(videoModeButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(140)
        }
        
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        controlsCard.addSubview(recordButton)
        recordButton.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        pauseButton.setTitle("Pause", for: .normal)
        pauseButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        pauseButton.isEnabled = false
        pauseButton.addTarget(self, action: #selector(pauseRecording), for: .touchUpInside)
        controlsCard.addSubview(pauseButton)
        pauseButton.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(80)
        }
        
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        stopButton.isEnabled = false
        stopButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        controlsCard.addSubview(stopButton)
        stopButton.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(80)
        }
        
        // Time display
        timeLabel.text = "Duration"
        timeLabel.font = StudioTheme.typography.label
        timeLabel.textColor = StudioTheme.colors.textSecondary
        controlsCard.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.bottom.left.equalToSuperview().inset(16)
        }
        
        timeValueLabel.text = "00:00"
        timeValueLabel.font = StudioTheme.typography.heading
        timeValueLabel.textColor = StudioTheme.colors.accentPurple
        controlsCard.addSubview(timeValueLabel)
        timeValueLabel.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview().inset(16)
        }
        
        // Level metering
        levelCard.layer.cornerRadius = 16
        contentView.addSubview(levelCard)
        levelCard.snp.makeConstraints { make in
            make.top.equalTo(controlsCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
        
        levelLabel.text = "Input Level"
        levelLabel.font = StudioTheme.typography.body
        levelLabel.textColor = StudioTheme.colors.textPrimary
        levelCard.addSubview(levelLabel)
        levelLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
        }
        
        levelMeterView.layer.cornerRadius = 8
        levelCard.addSubview(levelMeterView)
        levelMeterView.snp.makeConstraints { make in
            make.top.equalTo(levelLabel.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        // Info card
        infoCard.layer.cornerRadius = 16
        contentView.addSubview(infoCard)
        infoCard.snp.makeConstraints { make in
            make.top.equalTo(levelCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
        
        sampleRateLabel.text = "Sample Rate: 44.1 kHz"
        sampleRateLabel.font = StudioTheme.typography.label
        sampleRateLabel.textColor = StudioTheme.colors.textSecondary
        infoCard.addSubview(sampleRateLabel)
        sampleRateLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
        }
        
        bitDepthLabel.text = "Bit Depth: 16-bit"
        bitDepthLabel.font = StudioTheme.typography.label
        bitDepthLabel.textColor = StudioTheme.colors.textSecondary
        infoCard.addSubview(bitDepthLabel)
        bitDepthLabel.snp.makeConstraints { make in
            make.top.equalTo(sampleRateLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
        }
        
        fileFormatLabel.text = "Format: M4A"
        fileFormatLabel.font = StudioTheme.typography.label
        fileFormatLabel.textColor = StudioTheme.colors.textSecondary
        infoCard.addSubview(fileFormatLabel)
        fileFormatLabel.snp.makeConstraints { make in
            make.top.equalTo(bitDepthLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
        }
        
        // Save card (hidden initially)
        saveCard.layer.cornerRadius = 16
        saveCard.isHidden = true
        contentView.addSubview(saveCard)
        saveCard.snp.makeConstraints { make in
            make.top.equalTo(infoCard.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(140)
        }
        
        projectNameField.placeholder = "Project Name"
        projectNameField.font = StudioTheme.typography.body
        projectNameField.textColor = StudioTheme.colors.textPrimary
        projectNameField.borderStyle = .roundedRect
        projectNameField.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.1)
        saveCard.addSubview(projectNameField)
        projectNameField.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        saveButton.setTitle("Save Recording", for: .normal)
        saveButton.addTarget(self, action: #selector(saveRecording), for: .touchUpInside)
        saveCard.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(projectNameField.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        discardButton.setTitle("Discard", for: .normal)
        discardButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        discardButton.addTarget(self, action: #selector(discardRecording), for: .touchUpInside)
        saveCard.addSubview(discardButton)
        discardButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupAudioSession() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.record, mode: .default)
            try recordingSession?.setActive(true)
            Logger.shared.info("Audio session configured for recording")
        } catch {
            Logger.shared.error("Failed to setup audio session: \(error)")
            showAlert(title: "Error", message: "Failed to setup audio recording")
        }
    }
    
    @objc private func selectAudioMode() {
        selectedMode = .audio
        audioModeButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        videoModeButton.setTitleColor(StudioTheme.colors.textSecondary, for: .normal)
        Logger.shared.debug("Audio mode selected")
    }
    
    @objc private func selectVideoMode() {
        selectedMode = .video
        audioModeButton.setTitleColor(StudioTheme.colors.textSecondary, for: .normal)
        videoModeButton.setTitleColor(StudioTheme.colors.accentPurple, for: .normal)
        Logger.shared.debug("Video mode selected")
    }
    
    @objc private func startRecording() {
        // Request processing gate
        let canStart = processingGate.requestOperation(.recording)
        if !canStart {
            showAlert(title: "Recording Queued", message: "Another operation is in progress")
            return
        }
        
        do {
            // Create recording URL
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let recordingDir = documentsDir.appendingPathComponent("Recordings")
            try FileManager.default.createDirectory(at: recordingDir, withIntermediateDirectories: true)
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
            recordingURL = recordingDir.appendingPathComponent("Recording_\(timestamp).m4a")
            
            // Setup audio recorder
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            isPaused = false
            recordingDuration = 0
            
            // Update UI
            recordButton.isEnabled = false
            pauseButton.isEnabled = true
            stopButton.isEnabled = true
            
            // Start timer
            startRecordingTimer()
            
            Logger.shared.info("Recording started: \(recordingURL?.lastPathComponent ?? "unknown")")
        } catch {
            Logger.shared.error("Failed to start recording: \(error)")
            showAlert(title: "Error", message: "Failed to start recording: \(error.localizedDescription)")
            processingGate.completeOperation(.recording)
        }
    }
    
    @objc private func pauseRecording() {
        if isPaused {
            audioRecorder?.record()
            pauseButton.setTitle("Pause", for: .normal)
            isPaused = false
            Logger.shared.debug("Recording resumed")
        } else {
            audioRecorder?.pause()
            pauseButton.setTitle("Resume", for: .normal)
            isPaused = true
            Logger.shared.debug("Recording paused")
        }
    }
    
    @objc private func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        
        isRecording = false
        isPaused = false
        
        // Update UI
        recordButton.isEnabled = true
        pauseButton.isEnabled = false
        stopButton.isEnabled = false
        pauseButton.setTitle("Pause", for: .normal)
        
        // Show save options
        saveCard.isHidden = false
        projectNameField.text = "Recording_\(Date().timeIntervalSince1970)"
        
        Logger.shared.info("Recording stopped")
    }
    
    @objc private func saveRecording() {
        guard let recordingURL = recordingURL else {
            showAlert(title: "Error", message: "No recording to save")
            return
        }
        
        let projectName = projectNameField.text ?? "Recording"
        
        do {
            // Create project
            var project = StemProject(name: projectName)
            project.originalAudioURL = recordingURL
            project.duration = recordingDuration
            
            // Save project
            try projectStore.saveProject(project)
            
            // Reset UI
            saveCard.isHidden = true
            timeValueLabel.text = "00:00"
            recordingDuration = 0
            
            showAlert(title: "Success", message: "Recording saved as '\(projectName)'")
            Logger.shared.info("Recording saved: \(projectName)")
            
            processingGate.completeOperation(.recording)
        } catch {
            Logger.shared.error("Failed to save recording: \(error)")
            showAlert(title: "Error", message: "Failed to save recording")
        }
    }
    
    @objc private func discardRecording() {
        if let recordingURL = recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        
        recordingURL = nil
        saveCard.isHidden = true
        timeValueLabel.text = "00:00"
        recordingDuration = 0
        
        Logger.shared.info("Recording discarded")
        processingGate.completeOperation(.recording)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
            self?.updateTimeDisplay()
            
            // Update level meter
            if let level = self?.audioRecorder?.averagePower(forChannel: 0) {
                let normalizedLevel = pow(10, level / 20)
                DispatchQueue.main.async {
                    self?.levelMeterView.updateLevel(normalizedLevel)
                }
            }
        }
    }
    
    private func updateTimeDisplay() {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        let milliseconds = Int((recordingDuration.truncatingRemainder(dividingBy: 1)) * 100)
        
        DispatchQueue.main.async {
            self.timeValueLabel.text = String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVAudioRecorderDelegate

extension RecordingViewController: AVAudioRecorderDelegate {
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Logger.shared.error("Recording failed")
            showAlert(title: "Error", message: "Recording failed")
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Logger.shared.error("Recording encode error: \(error?.localizedDescription ?? "unknown")")
        showAlert(title: "Error", message: "Recording error: \(error?.localizedDescription ?? "unknown")")
    }
}
