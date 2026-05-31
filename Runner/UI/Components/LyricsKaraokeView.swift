import UIKit

/// LyricsKaraokeView displays synchronized lyrics with karaoke-style highlighting.
/// Shows current line, next line, and scrolls with playback.
public class LyricsKaraokeView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let glassBackgroundView = UIView()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Lyrics display
    private let currentLineLabel = UILabel()
    private let nextLineLabel = UILabel()
    private let previousLineLabel = UILabel()
    
    // Progress indicator
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let timeLabel = UILabel()
    
    // MARK: - Properties
    
    public struct LyricLine {
        public let text: String
        public let startTime: TimeInterval
        public let endTime: TimeInterval
        
        public init(text: String, startTime: TimeInterval, endTime: TimeInterval) {
            self.text = text
            self.startTime = startTime
            self.endTime = endTime
        }
    }
    
    private var lyrics: [LyricLine] = []
    private var currentLineIndex: Int = 0
    private var currentTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Glass background
        glassBackgroundView.backgroundColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.1)
        glassBackgroundView.layer.cornerRadius = 16
        glassBackgroundView.layer.borderWidth = 1
        glassBackgroundView.layer.borderColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2).cgColor
        
        // Apply glass effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        glassBackgroundView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(glassBackgroundView)
        glassBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Container
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Scroll view for lyrics
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(150)
        }
        
        // Content view
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        // Previous line (small, faded)
        previousLineLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        previousLineLabel.textColor = StudioTheme.colors.textSecondary.withAlphaComponent(0.5)
        previousLineLabel.textAlignment = .center
        previousLineLabel.numberOfLines = 2
        contentView.addSubview(previousLineLabel)
        previousLineLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        
        // Current line (large, highlighted)
        currentLineLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        currentLineLabel.textColor = StudioTheme.colors.accentPurple
        currentLineLabel.textAlignment = .center
        currentLineLabel.numberOfLines = 2
        contentView.addSubview(currentLineLabel)
        currentLineLabel.snp.makeConstraints { make in
            make.top.equalTo(previousLineLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Next line (medium, secondary)
        nextLineLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        nextLineLabel.textColor = StudioTheme.colors.textSecondary
        nextLineLabel.textAlignment = .center
        nextLineLabel.numberOfLines = 2
        contentView.addSubview(nextLineLabel)
        nextLineLabel.snp.makeConstraints { make in
            make.top.equalTo(currentLineLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        // Progress bar
        progressBar.progressTintColor = StudioTheme.colors.accentPurple
        progressBar.trackTintColor = StudioTheme.colors.accentPurple.withAlphaComponent(0.2)
        containerView.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(4)
        }
        
        // Time label
        timeLabel.text = "0:00 / 0:00"
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = StudioTheme.colors.textSecondary
        timeLabel.textAlignment = .center
        containerView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public API
    
    /// Load lyrics
    public func loadLyrics(_ lines: [LyricLine], totalDuration: TimeInterval) {
        lyrics = lines
        self.totalDuration = totalDuration
        currentLineIndex = 0
        
        if !lines.isEmpty {
            updateLyricsDisplay()
        }
    }
    
    /// Update playback time and sync lyrics
    public func updateTime(_ time: TimeInterval) {
        currentTime = time
        
        // Find current line
        var newIndex = 0
        for (index, line) in lyrics.enumerated() {
            if time >= line.startTime && time < line.endTime {
                newIndex = index
                break
            }
        }
        
        // Update if line changed
        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
            updateLyricsDisplay()
        }
        
        // Update progress bar
        let progress = totalDuration > 0 ? Float(time / totalDuration) : 0
        progressBar.progress = progress
        
        // Update time label
        timeLabel.text = "\(formatTime(time)) / \(formatTime(totalDuration))"
        
        // Scroll to keep current line visible
        scrollToCurrentLine()
    }
    
    /// Clear lyrics
    public func clear() {
        lyrics.removeAll()
        currentLineIndex = 0
        currentTime = 0
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.previousLineLabel.text = ""
            self.currentLineLabel.text = "No lyrics available"
            self.nextLineLabel.text = ""
            self.progressBar.progress = 0
            self.timeLabel.text = "0:00 / 0:00"
        })
    }
    
    // MARK: - Private Methods
    
    private func updateLyricsDisplay() {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            // Previous line
            if self.currentLineIndex > 0 {
                self.previousLineLabel.text = self.lyrics[self.currentLineIndex - 1].text
                self.previousLineLabel.alpha = 0.5
            } else {
                self.previousLineLabel.text = ""
            }
            
            // Current line
            if self.currentLineIndex < self.lyrics.count {
                self.currentLineLabel.text = self.lyrics[self.currentLineIndex].text
                self.currentLineLabel.alpha = 1.0
                
                // Animate current line
                self.currentLineLabel.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                UIView.animate(withDuration: 0.3) {
                    self.currentLineLabel.transform = CGAffineTransform.identity
                }
            }
            
            // Next line
            if self.currentLineIndex + 1 < self.lyrics.count {
                self.nextLineLabel.text = self.lyrics[self.currentLineIndex + 1].text
                self.nextLineLabel.alpha = 0.7
            } else {
                self.nextLineLabel.text = ""
            }
        })
    }
    
    private func scrollToCurrentLine() {
        // Calculate scroll position to keep current line centered
        let lineHeight: CGFloat = 60
        let targetOffset = CGFloat(currentLineIndex) * lineHeight - scrollView.bounds.height / 2
        
        scrollView.setContentOffset(
            CGPoint(x: 0, y: max(0, targetOffset)),
            animated: true
        )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
