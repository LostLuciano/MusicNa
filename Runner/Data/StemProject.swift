import Foundation

/// StemProject represents a complete music project with stems and metadata.
public struct StemProject: Codable {
    
    public let id: String
    public let name: String
    public let createdAt: Date
    public var updatedAt: Date
    
    // Audio files
    public var originalAudioURL: URL?
    public var stemURLs: [String: URL] = [:]  // stem name -> file URL
    
    // Analysis results
    public var chordData: ChordAnalysis?
    public var beatData: BeatAnalysis?
    
    // Mixer state
    public var stemVolumes: [String: Float] = [:]
    public var masterVolume: Float = 1.0
    public var mutedStems: Set<String> = []
    public var soloStem: String? = nil
    
    // Metadata
    public var duration: TimeInterval = 0
    public var bpm: Float = 0
    public var genre: String? = nil
    public var notes: String? = nil
    
    public init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Initialize stem volumes to 1.0
        for stem in ["vocals", "drums", "bass", "guitar", "piano", "other"] {
            self.stemVolumes[stem] = 1.0
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt
        case originalAudioPath, stemPaths
        case chordData, beatData
        case stemVolumes, masterVolume, mutedStems, soloStem
        case duration, bpm, genre, notes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Decode URLs from paths
        if let originalPath = try container.decodeIfPresent(String.self, forKey: .originalAudioPath) {
            self.originalAudioURL = URL(fileURLWithPath: originalPath)
        }
        
        if let stemPaths = try container.decodeIfPresent([String: String].self, forKey: .stemPaths) {
            self.stemURLs = stemPaths.mapValues { URL(fileURLWithPath: $0) }
        }
        
        self.chordData = try container.decodeIfPresent(ChordAnalysis.self, forKey: .chordData)
        self.beatData = try container.decodeIfPresent(BeatAnalysis.self, forKey: .beatData)
        
        self.stemVolumes = try container.decodeIfPresent([String: Float].self, forKey: .stemVolumes) ?? [:]
        self.masterVolume = try container.decodeIfPresent(Float.self, forKey: .masterVolume) ?? 1.0
        self.mutedStems = Set(try container.decodeIfPresent([String].self, forKey: .mutedStems) ?? [])
        self.soloStem = try container.decodeIfPresent(String.self, forKey: .soloStem)
        
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        self.bpm = try container.decodeIfPresent(Float.self, forKey: .bpm) ?? 0
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Encode URLs as paths
        if let url = originalAudioURL {
            try container.encode(url.path, forKey: .originalAudioPath)
        }
        
        let stemPaths = stemURLs.mapValues { $0.path }
        try container.encode(stemPaths, forKey: .stemPaths)
        
        try container.encodeIfPresent(chordData, forKey: .chordData)
        try container.encodeIfPresent(beatData, forKey: .beatData)
        
        try container.encode(stemVolumes, forKey: .stemVolumes)
        try container.encode(masterVolume, forKey: .masterVolume)
        try container.encode(Array(mutedStems), forKey: .mutedStems)
        try container.encodeIfPresent(soloStem, forKey: .soloStem)
        
        try container.encode(duration, forKey: .duration)
        try container.encode(bpm, forKey: .bpm)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - Analysis Data

public struct ChordAnalysis: Codable {
    public let chords: [ChordSegment]
    public let confidence: Float
    public let analyzedAt: Date
    
    public struct ChordSegment: Codable {
        public let name: String
        public let startTime: TimeInterval
        public let endTime: TimeInterval
        public let confidence: Float
    }
}

public struct BeatAnalysis: Codable {
    public let bpm: Float
    public let beats: [TimeInterval]
    public let confidence: Float
    public let analyzedAt: Date
}
