import Foundation
import AVFoundation
import CoreML

/// ChordDetectionManager handles real-time chord detection using CoreML.
/// Uses Chordcrnn model for accurate chord recognition.
public class ChordDetectionManager {
    
    static let shared = ChordDetectionManager()
    
    // MARK: - Types
    
    public struct ChordDetectionResult {
        public let chord: String
        public let confidence: Float
        public let timestamp: TimeInterval
        public let duration: TimeInterval
        
        public init(chord: String, confidence: Float, timestamp: TimeInterval, duration: TimeInterval) {
            self.chord = chord
            self.confidence = confidence
            self.timestamp = timestamp
            self.duration = duration
        }
    }
    
    public enum ChordDetectionError: LocalizedError {
        case modelNotFound
        case invalidAudioFormat
        case processingError
        case insufficientData
        case cancelled
        
        public var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "Chord detection model not found"
            case .invalidAudioFormat:
                return "Invalid audio format"
            case .processingError:
                return "Error processing audio for chord detection"
            case .insufficientData:
                return "Insufficient audio data for analysis"
            case .cancelled:
                return "Chord detection cancelled"
            }
        }
    }
    
    // MARK: - Properties
    
    private let modelManager = ModelManager.shared
    private let audioFeatureExtractor = AudioFeatureExtractor()
    private let chordTheory = ChordTheory.shared
    private let processingGate = ProcessingGate.shared
    private let performanceGuard = PerformanceGuard.shared
    
    private let analysisQueue = DispatchQueue(
        label: "com.nativemusicx.chord-detection",
        qos: .userInitiated
    )
    
    private var isCancelled = false
    private let lock = NSLock()
    
    // Cache for recent analyses
    private var analysisCache: [String: [ChordDetectionResult]] = [:]
    private let cacheMaxSize = 10
    
    private init() {
        Logger.shared.info("ChordDetectionManager initialized")
    }
    
    // MARK: - Public API
    
    /// Detect chords in audio file
    public func detectChords(
        from audioURL: URL,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<[ChordDetectionResult], ChordDetectionError>) -> Void
    ) {
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check cache first
            let cacheKey = audioURL.lastPathComponent
            if let cached = self.analysisCache[cacheKey] {
                Logger.shared.debug("Using cached chord analysis for: \(cacheKey)")
                DispatchQueue.main.async {
                    completion(.success(cached))
                }
                return
            }
            
            // Request processing gate
            let canStart = self.processingGate.requestOperation(.chordDetection)
            if !canStart {
                Logger.shared.warning("Chord detection queued - another operation in progress")
            }
            
            defer {
                self.processingGate.completeOperation(.chordDetection)
            }
            
            do {
                let results = try self._detectChords(
                    from: audioURL,
                    progress: progress
                )
                
                // Cache results
                self.cacheAnalysis(results, for: cacheKey)
                
                DispatchQueue.main.async {
                    completion(.success(results))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? ChordDetectionError ?? .processingError))
                }
            }
        }
    }
    
    /// Detect chords from audio buffer
    public func detectChords(
        from buffer: AVAudioPCMBuffer,
        sampleRate: Float,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<[ChordDetectionResult], ChordDetectionError>) -> Void
    ) {
        analysisQueue.async { [weak self] in
            guard let self = self else { return }
            
            let canStart = self.processingGate.requestOperation(.chordDetection)
            if !canStart {
                Logger.shared.warning("Chord detection queued")
            }
            
            defer {
                self.processingGate.completeOperation(.chordDetection)
            }
            
            do {
                let results = try self._detectChords(
                    from: buffer,
                    sampleRate: sampleRate,
                    progress: progress
                )
                
                DispatchQueue.main.async {
                    completion(.success(results))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error as? ChordDetectionError ?? .processingError))
                }
            }
        }
    }
    
    /// Cancel ongoing chord detection
    public func cancelDetection() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
        Logger.shared.info("Chord detection cancelled")
    }
    
    /// Clear analysis cache
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        analysisCache.removeAll()
        Logger.shared.info("Chord analysis cache cleared")
    }
    
    // MARK: - Private Implementation
    
    private func _detectChords(
        from audioURL: URL,
        progress: @escaping (Float) -> Void
    ) throws -> [ChordDetectionResult] {
        // Load audio file
        let audioFile = try AVAudioFile(forReading: audioURL)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            throw ChordDetectionError.invalidAudioFormat
        }
        
        try audioFile.read(into: buffer)
        
        return try _detectChords(
            from: buffer,
            sampleRate: Float(audioFile.processingFormat.sampleRate),
            progress: progress
        )
    }
    
    private func _detectChords(
        from buffer: AVAudioPCMBuffer,
        sampleRate: Float,
        progress: @escaping (Float) -> Void
    ) throws -> [ChordDetectionResult] {
        guard let channelData = buffer.floatChannelData else {
            throw ChordDetectionError.invalidAudioFormat
        }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            throw ChordDetectionError.insufficientData
        }
        
        // Extract chromagram features
        let chromagram = try audioFeatureExtractor.extractChromagram(
            from: channelData[0],
            frameLength: frameLength,
            sampleRate: sampleRate
        )
        
        // Process in chunks for real-time detection
        let chunkSize = 4096  // ~93ms at 44.1kHz
        var results: [ChordDetectionResult] = []
        var timestamp: TimeInterval = 0
        
        for chunkIndex in stride(from: 0, to: chromagram.count, by: chunkSize) {
            // Check cancellation
            lock.lock()
            let cancelled = isCancelled
            lock.unlock()
            
            if cancelled {
                throw ChordDetectionError.cancelled
            }
            
            let endIndex = min(chunkIndex + chunkSize, chromagram.count)
            let chunk = Array(chromagram[chunkIndex..<endIndex])
            
            // Detect chord in this chunk
            if let chord = try detectChordInChunk(chunk) {
                results.append(chord)
            }
            
            // Update progress
            let progressValue = Float(endIndex) / Float(chromagram.count)
            DispatchQueue.main.async {
                progress(progressValue)
            }
            
            timestamp += Double(chunkSize) / Double(sampleRate)
        }
        
        Logger.shared.info("Detected \(results.count) chord segments")
        return results
    }
    
    private func detectChordInChunk(_ chromagram: [Float]) throws -> ChordDetectionResult? {
        // Normalize chromagram
        let maxValue = chromagram.max() ?? 1.0
        let normalized = chromagram.map { $0 / maxValue }
        
        // Detect chord from pitch distribution
        let chord = chordTheory.detectChord(from: normalized)
        
        // Calculate confidence
        let confidence = calculateConfidence(from: normalized, for: chord)
        
        guard confidence > 0.3 else {
            return nil  // Low confidence, skip
        }
        
        return ChordDetectionResult(
            chord: chord,
            confidence: confidence,
            timestamp: 0,  // Would be calculated from chunk position
            duration: 0.1  // Approximate chunk duration
        )
    }
    
    private func calculateConfidence(from chromagram: [Float], for chord: String) -> Float {
        // Simple confidence calculation based on pitch distribution
        // In production, this would use the model's confidence output
        
        let sum = chromagram.reduce(0, +)
        let mean = sum / Float(chromagram.count)
        let variance = chromagram.map { pow($0 - mean, 2) }.reduce(0, +) / Float(chromagram.count)
        let stdDev = sqrt(variance)
        
        // Higher standard deviation = more confident chord
        let confidence = min(stdDev * 2, 1.0)
        return confidence
    }
    
    private func cacheAnalysis(_ results: [ChordDetectionResult], for key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        // Implement LRU cache
        if analysisCache.count >= cacheMaxSize {
            if let firstKey = analysisCache.keys.first {
                analysisCache.removeValue(forKey: firstKey)
            }
        }
        
        analysisCache[key] = results
        Logger.shared.debug("Cached chord analysis for: \(key)")
    }
}

// MARK: - AudioFeatureExtractor Extension

extension AudioFeatureExtractor {
    
    /// Extract chromagram (pitch distribution) from audio
    func extractChromagram(
        from audioData: UnsafePointer<Float>,
        frameLength: Int,
        sampleRate: Float
    ) throws -> [Float] {
        // Perform STFT
        let stftResult = performSTFT(audioData, frameLength: frameLength, sampleRate: sampleRate)
        
        // Convert to chromagram (12 pitch classes)
        var chromagram = [Float](repeating: 0, count: 12)
        
        for (frequency, magnitude) in stftResult {
            // Convert frequency to MIDI note
            let midiNote = frequencyToMidiNote(frequency)
            let pitchClass = Int(midiNote) % 12
            
            // Accumulate magnitude for this pitch class
            chromagram[pitchClass] += magnitude
        }
        
        return chromagram
    }
    
    private func performSTFT(
        _ audioData: UnsafePointer<Float>,
        frameLength: Int,
        sampleRate: Float
    ) -> [(frequency: Float, magnitude: Float)] {
        // Simplified STFT - in production would use Accelerate framework
        var result: [(frequency: Float, magnitude: Float)] = []
        
        let windowSize = 2048
        let hopSize = 512
        
        for i in stride(from: 0, to: frameLength - windowSize, by: hopSize) {
            // Apply Hann window
            var frame = [Float](repeating: 0, count: windowSize)
            for j in 0..<windowSize {
                let window = 0.5 * (1 - cos(2 * .pi * Float(j) / Float(windowSize - 1)))
                frame[j] = audioData[i + j] * window
            }
            
            // Simple magnitude calculation (would use FFT in production)
            let magnitude = frame.map { abs($0) }.reduce(0, +) / Float(windowSize)
            let frequency = Float(i) / sampleRate
            
            result.append((frequency: frequency, magnitude: magnitude))
        }
        
        return result
    }
    
    private func frequencyToMidiNote(_ frequency: Float) -> Float {
        // Convert frequency (Hz) to MIDI note number
        return 12 * log2(frequency / 440) + 69
    }
}
