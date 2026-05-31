import UIKit
import AVFoundation

/// Displays waveform from audio file with playback position indicator
public class WaveformView: UIView {
    
    private let waveformLayer = CAShapeLayer()
    private let playheadLayer = CAShapeLayer()
    private var waveformData: [Float] = []
    private var currentPosition: TimeInterval = 0
    private var duration: TimeInterval = 0
    
    public var waveformColor: UIColor = StudioColors.purpleAccent {
        didSet {
            waveformLayer.strokeColor = waveformColor.cgColor
        }
    }
    
    public var playheadColor: UIColor = StudioColors.purpleGlow {
        didSet {
            playheadLayer.fillColor = playheadColor.cgColor
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = StudioColors.glassDark
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Waveform layer
        waveformLayer.fillColor = UIColor.clear.cgColor
        waveformLayer.strokeColor = waveformColor.cgColor
        waveformLayer.lineWidth = 1.5
        layer.addSublayer(waveformLayer)
        
        // Playhead layer
        playheadLayer.fillColor = playheadColor.cgColor
        layer.addSublayer(playheadLayer)
    }
    
    /// Load waveform from audio file
    public func loadWaveform(from audioURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let audioFile = try AVAudioFile(forReading: audioURL)
                let format = audioFile.processingFormat
                let frameCount = Int(audioFile.length)
                
                self.duration = Double(frameCount) / format.sampleRate
                
                // Read audio data
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
                    return
                }
                
                try audioFile.read(into: buffer)
                
                // Downsample to waveform data
                let downsampleFactor = max(1, frameCount / 512) // Target 512 samples
                var waveformData: [Float] = []
                
                if let channelData = buffer.floatChannelData {
                    let channel = channelData[0]
                    
                    for i in stride(from: 0, to: frameCount, by: downsampleFactor) {
                        let endIndex = min(i + downsampleFactor, frameCount)
                        var maxValue: Float = 0
                        
                        for j in i..<endIndex {
                            maxValue = max(maxValue, abs(channel[j]))
                        }
                        
                        waveformData.append(maxValue)
                    }
                }
                
                DispatchQueue.main.async {
                    self.waveformData = waveformData
                    self.drawWaveform()
                }
                
            } catch {
                Logger.shared.error("Failed to load waveform: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update playback position
    public func updatePlaybackPosition(_ position: TimeInterval) {
        currentPosition = position
        updatePlayhead()
    }
    
    private func drawWaveform() {
        guard !waveformData.isEmpty else { return }
        
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let centerY = height / 2
        
        for (index, value) in waveformData.enumerated() {
            let x = CGFloat(index) / CGFloat(waveformData.count) * width
            let y = centerY - (CGFloat(value) * centerY)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        waveformLayer.path = path.cgPath
    }
    
    private func updatePlayhead() {
        guard duration > 0 else { return }
        
        let progress = currentPosition / duration
        let x = bounds.width * CGFloat(progress)
        
        let playheadPath = UIBezierPath()
        playheadPath.move(to: CGPoint(x: x, y: 0))
        playheadPath.addLine(to: CGPoint(x: x, y: bounds.height))
        
        playheadLayer.path = playheadPath.cgPath
        playheadLayer.lineWidth = 2
        playheadLayer.strokeColor = playheadColor.cgColor
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        waveformLayer.frame = bounds
        playheadLayer.frame = bounds
        drawWaveform()
    }
}
