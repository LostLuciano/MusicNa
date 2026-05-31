import UIKit

/// Studio mixer screen - real-time stem mixing
public class MixerViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Now playing
    private let nowPlayingCard = GlassCardView()
    private let trackTitleLabel = UILabel()
    private let waveformView = WaveformView()
    private let timeLabel = UILabel()
    private let durationLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    
    // Stem channels
    private let channelsStackView = UIStackView()
    private var stemChannels: [StemChannelView] = []
    
    // Export
    private let exportButton = PurpleGlowButton()
    
    private let audioEngine = AudioEngineManager()
    private let projectStore = ProjectStore.shared
    
    public var project: StemProject?
    private var playbackTimer: Timer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProject()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayback()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Studio Mixer", subtitle: "Real-time Mixing")
        
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
        
        setupNowPlayingCard()
        setupStemChannels()
        setupExportButton()
    }
    
    private func setupNowPlayingCard() {
        nowPlayingCard.setupGlassCard()
        contentView.addSubview(nowPlayingCard)
        
        nowPlayingCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nowPlayingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nowPlayingCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nowPlayingCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nowPlayingCard.heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // Title
        trackTitleLabel.font = Typography.heading3
        trackTitleLabel.textColor = StudioColors.textPrimary
        nowPlayingCard.addSubview(trackTitleLabel)
        
        trackTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trackTitleLabel.leadingAnchor.constraint(equalTo: nowPlayingCard.leadingAnchor, constant: 12),
            trackTitleLabel.topAnchor.constraint(equalTo: nowPlayingCard.topAnchor, constant: 12)
        ])
        
        // Waveform
        waveformView.waveformColor = StudioColors.purpleAccent
        nowPlayingCard.addSubview(waveformView)
        
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            waveformView.leadingAnchor.constraint(equalTo: nowPlayingCard.leadingAnchor, constant: 12),
            waveformView.trailingAnchor.constraint(equalTo: nowPlayingCard.trailingAnchor, constant: -12),
            waveformView.topAnchor.constraint(equalTo: trackTitleLabel.bottomAnchor, constant: 12),
            waveformView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Time labels
        timeLabel.font = Typography.monospaceMedium
        timeLabel.textColor = StudioColors.textSecondary
        nowPlayingCard.addSubview(timeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: nowPlayingCard.leadingAnchor, constant: 12),
            timeLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 8)
        ])
        
        durationLabel.font = Typography.monospaceMedium
        durationLabel.textColor = StudioColors.textSecondary
        durationLabel.textAlignment = .right
        nowPlayingCard.addSubview(durationLabel)
        
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            durationLabel.trailingAnchor.constraint(equalTo: nowPlayingCard.trailingAnchor, constant: -12),
            durationLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 8)
        ])
        
        // Playback buttons
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        nowPlayingCard.addSubview(buttonStackView)
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: nowPlayingCard.leadingAnchor, constant: 12),
            buttonStackView.trailingAnchor.constraint(equalTo: nowPlayingCard.trailingAnchor, constant: -12),
            buttonStackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            buttonStackView.bottomAnchor.constraint(equalTo: nowPlayingCard.bottomAnchor, constant: -12)
        ])
        
        // Play button
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = StudioColors.purpleAccent
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(playButton)
        
        // Pause button
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        pauseButton.tintColor = StudioColors.purpleAccent
        pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(pauseButton)
        
        // Stop button
        stopButton.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        stopButton.tintColor = StudioColors.purpleAccent
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(stopButton)
    }
    
    private func setupStemChannels() {
        let channelsLabel = UILabel()
        channelsLabel.text = "STEM MIXER"
        channelsLabel.font = Typography.labelSmall
        channelsLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(channelsLabel)
        
        channelsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            channelsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            channelsLabel.topAnchor.constraint(equalTo: nowPlayingCard.bottomAnchor, constant: 24)
        ])
        
        // Channels stack
        channelsStackView.axis = .vertical
        channelsStackView.spacing = 12
        contentView.addSubview(channelsStackView)
        
        channelsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            channelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            channelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            channelsStackView.topAnchor.constraint(equalTo: channelsLabel.bottomAnchor, constant: 12)
        ])
        
        // Create channels
        let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
        for stemName in stemNames {
            let channel = StemChannelView()
            channel.stemName = stemName
            channel.delegate = self
            channelsStackView.addArrangedSubview(channel)
            stemChannels.append(channel)
        }
    }
    
    private func setupExportButton() {
        exportButton.setTitle("Export Mix to Stereo M4A", font: Typography.labelLarge)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        contentView.addSubview(exportButton)
        
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            exportButton.topAnchor.constraint(equalTo: channelsStackView.bottomAnchor, constant: 24),
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            exportButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func loadProject() {
        guard let project = project else { return }
        
        trackTitleLabel.text = project.name
        durationLabel.text = formatTime(project.duration)
        
        do {
            try audioEngine.loadStemFiles(project.stemURLs)
            
            // Load waveform
            if let audioURL = project.originalAudioURL {
                waveformView.loadWaveform(from: audioURL)
            }
        } catch {
            Logger.shared.error("Failed to load project: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Playback Controls
    
    @objc private func playTapped() {
        do {
            try audioEngine.play()
            startPlaybackTimer()
        } catch {
            Logger.shared.error("Failed to play: \(error.localizedDescription)")
        }
    }
    
    @objc private func pauseTapped() {
        audioEngine.pause()
        stopPlaybackTimer()
    }
    
    @objc private func stopTapped() {
        audioEngine.stop()
        stopPlaybackTimer()
        timeLabel.text = "00:00"
        waveformView.updatePlaybackPosition(0)
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackPosition()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackPosition() {
        // Update time label and waveform
        let currentTime = 0.0 // Would get from audioEngine
        timeLabel.text = formatTime(currentTime)
        waveformView.updatePlaybackPosition(currentTime)
    }
    
    @objc private func exportTapped() {
        showAlert(title: "Export", message: "Export functionality coming soon")
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - StemChannelDelegate

extension MixerViewController: StemChannelDelegate {
    
    func stemChannel(_ channel: StemChannelView, volumeDidChange volume: Float) {
        audioEngine.setVolume(stem: channel.stemName, volume: volume)
        
        if var project = project {
            project.stemVolumes[channel.stemName] = volume
            try? projectStore.saveProject(project)
        }
    }
    
    func stemChannel(_ channel: StemChannelView, muteDidChange muted: Bool) {
        audioEngine.muteStem(channel.stemName, muted: muted)
    }
    
    func stemChannel(_ channel: StemChannelView, soloDidChange solo: Bool) {
        if solo {
            audioEngine.soloStem(channel.stemName)
        } else {
            // Unmute all
            for stemName in ["vocals", "drums", "bass", "guitar", "piano", "other"] {
                audioEngine.muteStem(stemName, muted: false)
            }
        }
    }
}
