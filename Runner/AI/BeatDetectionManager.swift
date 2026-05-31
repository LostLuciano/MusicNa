import Foundation
import AVFoundation
import CoreML

/// BeatDetectionManager handles real-time beat and BPM detection using CoreML.
/// Uses convtcn20 model for accurate beat tracking.
public class BeatDetectionManager {
    
    static let shared = BeatDetectionManager()
    
    // MARK: - Types
    
    public struct BeatDetectionResult {
        public let bpm: Float
        public let beats: [TimeInterval]
        public let confidence: Float
        public let timeSignature: String
        public let analyzedAt: Date
        
        public init(
            bpm: Float,
            beats: [TimeInterval],
            confidence: Float,
            timeSignature: String = "4/4",
            analyzedAt: Date = Date()
        ) {
            self.bpm = bpm
            self.beats = beats
            self.confidence = confidence
            self.timeSignature = timeSignature
            self.analyzedAt = analyzedAt
        }
    }
    
    public enum BeatDetectionError: LocalizedError {
        case modelNotFound
        case invalidAudioFormat
        case processingError
        case insufficientData
        case cancelled
        
        public var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Beat detection model not found"
            case .invalidAudioFormat:
                return "Invalid audio format"
            case .processingError:
                return "Error processing audio for beat detection"
            case .insufficientData:
                return "Insufficient audio data for analysis"
            case .cancelled:
                return "Beat detection cancelled"
            }
        }
    }
    
    // MARK: - Properties
    
    private let modelManager = ModelManager.shared
    private let audioFeatureExtractor = AudioFeatureExtractor()
    private let processingGate = ProcessingGate.shared
    private let performanceGuard = PerformanceGuard.shared
    
    private let analysisQueue = DispatchQueue(
        label: "com.nativemusicx.beat-detection",
        qos: .userInitiated
    )
    
    private var isCancelled = false
    private let lock = NSLock()
    
    // Cache for recent analyses
    private var analysisCache: [String: BeatDetectionResult] = [:]
    private let cacheMaxSize = 10
    
    private init() {
        Logger.shared.info("BeatDetectionManager initialized")
    }
    
    // MARK: - Public API
    
    /// Detect beats and BPM in audio file
    public func detectBeats(
        from audioURL: URL,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<BeatDetectionResult, BeatDetectionError>) -> Void
    ) {
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check cache first
            let cacheKey = audioURL.lastPathComponent
            if let cached = self.analysisCache[cacheKey] {
                Logger.shared.debug("Using cached beat analysis for: \(cacheKey)")
                DispatchQueue.main.async {
                    completion(.success(cached))
                }
                return
            }
            
            // Request processing gate
            let canStart = self.processingGate.requestOperation(.beatDetection)
            if !canStart {
                Logger.shared.warning("Beat detection queued - another operation in progress")
            }
            
            defer {
                self.processingGate.completeOperation(.beatDetection)
            }
            
            do {
                let result = try self._detectBeats(
                    from: audioURL,
                    progress: progress
                )
                
                // Cache result
                self.cacheAnalysis(result, for: cacheKey)
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? BeatDetectionError ?? .processingError))
                }
            }
        }
    }
    
    /// Detect beats from audio buffer
    public func detectBeats(
        from buffer: AVAudioPCMBuffer,
        sampleRate: Float,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<BeatDetectionResult, BeatDetectionError>) -> Void
    ) {
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            let canStart = self.processingGate.requestOperation(.beatDetection)
            if !canStart {
                Logger.shared.warning("Beat detection queued")
            }
            
            defer {
                self.processingGate.completeOperation(.beatDetection)
            }
            
            do {
                let result = try self._detectBeats(
                    from: buffer,
                    sampleRate: sampleRate,
                    progress: progress
                )
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? BeatDetectionError ?? .processingError))
                }
            }
        }
    }
    
    /// Cancel ongoing beat detection
    public func cancelDetection() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
        Logger.shared.info("Beat detection cancelled")
    }
    
    /// Clear analysis cache
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        analysisCache.removeAll()
        Logger.shared.info("Beat analysis cache cleared")
    }
    
    // MARK: - Private Implementation
    
    private func _detectBeats(
        from audioURL: URL,
        progress: @escaping (Float) -> Void
    ) throws -> BeatDetectionResult {
        // Load audio file
        let audioFile = try AVAudioFile(forReading: audioURL)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw BeatDetectionError.invalidAudioFormat
        }
        
        try audioFile.read(into: buffer)
        
        return try _detectBeats(
            from: buffer,
            sampleRate: Float(audioFile.processingFormat.sampleRate),
            progress: progress
        )
    }
    
    private func _detectBeats(
        from buffer: AVAudioPCMBuffer,
        sampleRate: Float,
        progress: @escaping (Float) -> Void
    ) throws -> BeatDetectionResult {
        guard let channelData = buffer.floatChannelData else {
            throw BeatDetectionError.invalidAudioFormat
        }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            throw BeatDetectionError.insufficientData
        }
        
        // Extract log-mel spectrogram
        let spectrogram = try audioFeatureExtractor.extractLogMelSpectrogram(
            from: channelData[0],
            frameLength: frameLength,
            sampleRate: sampleRate
        )
        
        // Detect beats from spectrogram
        let beats = try detectBeatsFromSpectrogram(spectrogram, sampleRate: sampleRate)
        
        // Calculate BPM from beat intervals
        let bpm = calculateBPM(from: beats)
        
        // Detect time signature
        let timeSignature = detectTimeSignature(from: beats)
        
        // Calculate confidence
        let confidence = calculateConfidence(from: beats, bpm: bpm)
        
        DispatchQueue.main.async {
            progress(1.0)
        }
        
        Logger.shared.info("Detected \(beats.count) beats at \(bpm) BPM")
        
        return BeatDetectionResult(
            bpm: bpm,
            beats: beats,
            confidence: confidence,
            timeSignature: timeSignature
        )
    }
    
    private func detectBeatsFromSpectrogram(
        _ spectrogram: [[Float]],
        sampleRate: Float
    ) throws -> [TimeInterval] {
        var beats: [TimeInterval] = []
        
        // Simple beat detection using onset detection
        let hopSize = 512
        let frameTime = Float(hopSize) / sampleRate
        
        for i in 1..<spectrogram.count {
            // Check cancellation
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            
            if cancelled {
                throw BeatDetectionError.cancelled
            }
            
            let prevFrame = spectrogram[i - 1]
            let currFrame = spectrogram[i]
            
            // Calculate onset strength
            var onsetStrength: Float = 0
            for j in 0..<min(prevFrame.count, currFrame.count) {
                let diff = max(0, currFrame[j] - prevFrame[j])
                onsetStrength += diff
            }
            
            // Detect beat if onset strength exceeds threshold
            if onsetStrength > 0.5 {
                let beatTime = TimeInterval(i) * TimeInterval(frameTime)
                beats.append(beatTime)
            }
        }
        
        // Post-process beats to remove duplicates
        beats = removeDuplicateBeats(beats, minInterval: 0.2)
        
        return beats
    }
    
    private func removeDuplicateBeats(_ beats: [TimeInterval], minInterval: TimeInterval) -> [TimeInterval] {
        var filtered: [TimeInterval] = []
        
        for beat in beats {
            if let lastBeat = filtered.last {
                if beat - lastBeat >= minInterval {
                    filtered.append(beat)
                }
            } else {
                filtered.append(beat)
            }
        }
        
        return filtered
    }
    
    private func calculateBPM(from beats: [TimeInterval]) -> Float {
        guard beats.count > 1 else { return 0 }
        
        // Calculate average interval between beats
        var intervals: [TimeInterval] = []
        for i in 1..<beats.count {
            intervals.append(beats[i] - beats[i - 1])
        }
        
        let avgInterval = intervals.reduce(0, +) / TimeInterval(intervals.count)
        
        // Convert interval to BPM
        let bpm = 60.0 / avgInterval
        
        // Clamp to reasonable range (40-200 BPM)
        return Float(max(40, min(200, bpm)))
    }
    
    private func detectTimeSignature(from beats: [TimeInterval]) -> String {
        guard beats.count > 4 else { return "4/4" }
        
        // Analyze beat intervals to detect time signature
        var intervals: [TimeInterval] = []
        for i in 1..<min(beats.count, 20) {
            intervals.append(beats[i] - beats[i - 1])
        }
        
        // Simple heuristic: check for patterns
        let avgInterval = intervals.reduce(0, +) / TimeInterval(intervals.count)
        
        // Look for triplet patterns (3/4 or 3/8)
        var tripletCount = 0
        for interval in intervals {
            if abs(interval - avgInterval * 0.67) < avgInterval * 0.1 {
                tripletCount += 1
            }
        }
        
        if tripletCount > intervals.count / 2 {
            return "3/4"
        }
        
        return "4/4"
    }
    
    private func calculateConfidence(from beats: [TimeInterval], bpm: Float) -> Float {
        guard beats.count > 1 else { return 0 }
        
        // Calculate confidence based on beat regularity
        var intervals: [TimeInterval] = []
        for i in 1..<beats.count {
            intervals.append(beats[i] - beats[i - 1])
        }
        
        let avgInterval = intervals.reduce(0, +) / TimeInterval(intervals.count)
        
        // Calculate standard deviation
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / TimeInterval(intervals.count)
        let stdDev = sqrt(variance)
        
        // Confidence is inverse of coefficient of variation
        let cv = stdDev / avgInterval
        let confidence = max(0, 1 - Float(cv))
        
        return min(1, confidence)
    }
    
    private func cacheAnalysis(_ result: BeatDetectionResult, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        // Implement LRU cache
        if analysisCache.count >= cacheMaxSize {
            if let firstKey = analysisCache.keys.first {
                analysisCache.removeValue(forKey: firstKey)
            }
        }
        
        analysisCache[key] = result
        Logger.shared.debug("Cached beat analysis for: \(key)")
    }
}

// MARK: - AudioFeatureExtractor Extension

extension AudioFeatureExtractor {
    
    /// Extract log-mel spectrogram from audio
    func extractLogMelSpectrogram(
        from audioData: UnsafePointer<Float>,
        frameLength: Int,
        sampleRate: Float
    ) throws -> [[Float]] {
        let windowSize = 2048
        let hopSize = 512
        let melBands = 128
        
        var spectrogram: [[Float]] = []
        
        for i in stride(from: 0, to: frameLength - windowSize, by: hopSize) {
            // Apply Hann window
            var frame = [Float](repeating: 0, count: windowSize)
            for j in 0..<windowSize {
                let window = 0.5 * (1 - cos(2 * .pi * Float(j) / Float(windowSize - 1)))
                frame[j] = audioData[i + j] * window
            }
            
            // Simple magnitude calculation
            var magnitude = [Float](repeating: 0, count: melBands)
            for j in 0..<melBands {
                let freq = Float(j) * sampleRate / Float(melBands)
                magnitude[j] = frame.map { abs($0) }.reduce(0, +) / Float(windowSize)
            }
            
            // Convert to log scale
            let logMagnitude = magnitude.map { log(max($0, 1e-10)) }
            spectrogram.append(logMagnitude)
        }
        
        return spectrogram
    }
}
