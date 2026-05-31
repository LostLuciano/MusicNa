import Foundation
import AVFoundation
import MobileCoreServices

/// FileImportManager handles secure audio/video file imports from iPhone Files app.
/// Supports: MP3, WAV, M4A, AAC, AIFF, MP4, MOV, FLAC, and other audio formats.
public class FileImportManager: NSObject, UIDocumentPickerDelegate {
    
    static let shared = FileImportManager()
    
    private let cacheManager = CacheManager.shared
    private let performanceGuard = PerformanceGuard.shared
    
    // Supported formats
    private let supportedAudioFormats = [
        "com.apple.m4a-audio",           // M4A
        "com.apple.protected-mpeg-4-audio", // Protected M4A
        "public.mp3",                    // MP3
        "com.microsoft.waveform-audio",  // WAV
        "public.aiff-audio",             // AIFF
        "public.flac",                   // FLAC
        "com.apple.coreaudio-format",    // CAF
        "public.aac-audio",              // AAC
    ]
    
    private let supportedVideoFormats = [
        "public.mpeg-4",                 // MP4
        "public.quicktime",              // MOV
        "com.apple.quicktime-movie",     // MOV
    ]
    
    private var importCompletion: ((Result<URL, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    /// Present document picker for audio/video file selection
    public func presentFilePicker(from viewController: UIViewController, completion: @escaping (Result<URL, Error>) -> Void) {
        self.importCompletion = completion
        
        let allFormats = supportedAudioFormats + supportedVideoFormats
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allFormats.compactMap { UTType($0) })
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        viewController.present(documentPicker, animated: true)
        Logger.shared.info("📂 Presented file picker for audio/video import")
    }
    
    /// Validate if file is supported audio/video format
    public func isFileSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = [
            "mp3", "wav", "m4a", "aac", "aiff", "flac", "caf",
            "mp4", "mov"
        ]
        return supportedExtensions.contains(fileExtension)
    }
    
    /// Get file information
    public func getFileInfo(_ url: URL) throws -> FileInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        let creationDate = attributes[.creationDate] as? Date ?? Date()
        
        // Try to get audio duration
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        return FileInfo(
            url: url,
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            duration: durationSeconds,
            createdAt: creationDate,
            isVideo: isVideoFile(url)
        )
    }
    
    public struct FileInfo {
        public let url: URL
        public let fileName: String
        public let fileSize: UInt64
        public let duration: TimeInterval
        public let createdAt: Date
        public let isVideo: Bool
        
        public var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(fileSize))
        }
        
        public var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else {
            importCompletion?(.failure(NSError(domain: "FileImportManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "No file selected"])))
            return
        }
        
        performanceGuard.startOperation("File Import")
        
        // Start accessing security-scoped resource
        let securityScoped = selectedURL.startAccessingSecurityScopedResource()
        defer {
            if securityScoped {
                selectedURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Validate file
            guard isFileSupported(selectedURL) else {
                throw NSError(domain: "FileImportManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "File format not supported"])
            }
            
            performanceGuard.addCheckpoint("File Import", checkpoint: "Format validated")
            
            // Get file info
            let fileInfo = try getFileInfoSync(selectedURL)
            Logger.shared.info("📥 Selected file: \(fileInfo.fileName) (\(fileInfo.formattedSize), \(fileInfo.formattedDuration))")
            
            performanceGuard.addCheckpoint("File Import", checkpoint: "File info retrieved")
            
            // Copy to cache
            let cachedURL = try cacheManager.cacheImportedFile(selectedURL)
            
            performanceGuard.addCheckpoint("File Import", checkpoint: "File cached")
            performanceGuard.endOperation("File Import")
            
            Logger.shared.info("✅ File import completed: \(cachedURL.lastPathComponent)")
            importCompletion?(.success(cachedURL))
            
        } catch {
            performanceGuard.endOperation("File Import")
            Logger.shared.error("❌ File import failed: \(error.localizedDescription)")
            importCompletion?(.failure(error))
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        Logger.shared.info("📂 File picker cancelled")
        importCompletion?(.failure(NSError(domain: "FileImportManager", code: 100, userInfo: [NSLocalizedDescriptionKey: "User cancelled file selection"])))
    }
    
    // MARK: - Private Helpers
    
    private func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
    
    private func getFileInfoSync(_ url: URL) throws -> FileInfo {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        let creationDate = attributes[.creationDate] as? Date ?? Date()
        
        // Get audio duration synchronously
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        return FileInfo(
            url: url,
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            duration: duration,
            createdAt: creationDate,
            isVideo: isVideoFile(url)
        )
    }
}
