import Foundation

/// TrackMetadata stores information about audio tracks (demo or imported).
public struct TrackMetadata: Codable, Identifiable {
    
    public let id: String
    public let name: String
    public let artist: String?
    public let genre: String?
    public let duration: TimeInterval
    public let isDemo: Bool
    
    // File paths
    public let originalAudioPath: String?
    public let stemPaths: [String: String]?  // stem name -> path
    public let analysisDataPath: String?
    
    // Analysis data
    public let bpm: Float?
    public let chords: [String]?
    
    // Metadata
    public let createdAt: Date
    public let lastModified: Date
    
    public init(
        name: String,
        artist: String? = nil,
        genre: String? = nil,
        duration: TimeInterval,
        isDemo: Bool = false,
        originalAudioPath: String? = nil,
        stemPaths: [String: String]? = nil,
        analysisDataPath: String? = nil,
        bpm: Float? = nil,
        chords: [String]? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.artist = artist
        self.genre = genre
        self.duration = duration
        self.isDemo = isDemo
        self.originalAudioPath = originalAudioPath
        self.stemPaths = stemPaths
        self.analysisDataPath = analysisDataPath
        self.bpm = bpm
        self.chords = chords
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // MARK: - Computed Properties
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var displayName: String {
        if let artist = artist {
            return "\(name) - \(artist)"
        }
        return name
    }
    
    public var hasStemData: Bool {
        return stemPaths != nil && !stemPaths!.isEmpty
    }
    
    public var hasAnalysisData: Bool {
        return analysisDataPath != nil
    }
}

// MARK: - Demo Track Definitions

public struct DemoTrackLibrary {
    
    public static let tracks: [TrackMetadata] = [
        TrackMetadata(
            name: "Classical Symphony",
            artist: "Demo",
            genre: "Classical",
            duration: 150,
            isDemo: true,
            originalAudioPath: "classical.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "classical-analysis-data.json",
            bpm: 120,
            chords: ["C", "G", "Am", "F"]
        ),
        TrackMetadata(
            name: "Trap Beats",
            artist: "Demo",
            genre: "Trap",
            duration: 120,
            isDemo: true,
            originalAudioPath: "trap.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "trap-analysis-data.json",
            bpm: 140,
            chords: ["Dm", "Bb", "F", "C"]
        ),
        TrackMetadata(
            name: "EDM Dance",
            artist: "Demo",
            genre: "EDM",
            duration: 135,
            isDemo: true,
            originalAudioPath: "edm.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "edm-analysis-data.json",
            bpm: 128,
            chords: ["A", "E", "B", "F#m"]
        ),
        TrackMetadata(
            name: "Dubstep Wobble",
            artist: "Demo",
            genre: "Dubstep",
            duration: 130,
            isDemo: true,
            originalAudioPath: "dubstep.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "dubstep-analysis-data.json",
            bpm: 140,
            chords: ["Eb", "Bb", "F", "Cm"]
        ),
        TrackMetadata(
            name: "Country Road",
            artist: "Demo",
            genre: "Country",
            duration: 140,
            isDemo: true,
            originalAudioPath: "country.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "country-analysis-data.json",
            bpm: 100,
            chords: ["G", "D", "A", "Em"]
        ),
        TrackMetadata(
            name: "Drum & Bass",
            artist: "Demo",
            genre: "Drum & Bass",
            duration: 125,
            isDemo: true,
            originalAudioPath: "drumNBass.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "drumNBass-analysis-data.json",
            bpm: 170,
            chords: ["Gm", "Eb", "Bb", "F"]
        ),
        TrackMetadata(
            name: "Folk Rock",
            artist: "Demo",
            genre: "Folk Rock",
            duration: 145,
            isDemo: true,
            originalAudioPath: "folkRock.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "folkRock-analysis-data.json",
            bpm: 110,
            chords: ["D", "A", "Bm", "G"]
        ),
        TrackMetadata(
            name: "Latino Vibes",
            artist: "Demo",
            genre: "Latino",
            duration: 135,
            isDemo: true,
            originalAudioPath: "latino.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "latino-analysis-data.json",
            bpm: 95,
            chords: ["Cm", "G", "Bb", "Eb"]
        ),
        TrackMetadata(
            name: "Heavy Metal",
            artist: "Demo",
            genre: "Metal",
            duration: 150,
            isDemo: true,
            originalAudioPath: "metal.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "metal-analysis-data.json",
            bpm: 160,
            chords: ["Em", "B", "G", "D"]
        ),
        TrackMetadata(
            name: "Reggaeton Dance",
            artist: "Demo",
            genre: "Reggaeton",
            duration: 130,
            isDemo: true,
            originalAudioPath: "reggaeton.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "reggaeton-analysis-data.json",
            bpm: 92,
            chords: ["Am", "E", "Dm", "G"]
        ),
        TrackMetadata(
            name: "RnB Soul",
            artist: "Demo",
            genre: "R&B",
            duration: 140,
            isDemo: true,
            originalAudioPath: "rnb.caf",
            stemPaths: [
                "vocals": "Vocals.m4a",
                "drums": "Drums.m4a",
                "bass": "Others.m4a",
                "guitar": "Guitar.m4a",
                "piano": "Others.m4a",
                "other": "Others.m4a"
            ],
            analysisDataPath: "rnb-analysis-data.json",
            bpm: 90,
            chords: ["Fm", "Cm", "Bb", "Eb"]
        )
    ]
    
    public static func getTrack(byName name: String) -> TrackMetadata? {
        return tracks.first { $0.name == name }
    }
    
    public static func getTrack(byId id: String) -> TrackMetadata? {
        return tracks.first { $0.id == id }
    }
}
