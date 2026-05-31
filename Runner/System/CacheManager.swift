import Foundation

/// CacheManager handles temporary file storage, cleanup, and lifecycle management.
/// Ensures efficient use of disk space and prevents orphaned files.
public class CacheManager {
    
    static let shared = CacheManager()
    
    private let lock = NSLock()
    private let fileManager = FileManager.default
    
    // Cache directories
    private let cacheDir: URL
    private let importsDir: URL
    private let outputDir: URL
    private let tempDir: URL
    
    // Tracking
    private var trackedFiles: [String: CachedFile] = [:]
    
    public struct CachedFile {
        let url: URL
        let createdAt: Date
        let category: String // "import", "output", "temp"
        var accessedAt: Date
        var size: UInt64 = 0
    }
    
    // Configuration
    private let maxCacheSize: UInt64 = 2 * 1024 * 1024 * 1024 // 2 GB
    private let fileExpirationTime: TimeInterval = 86400 * 7 // 7 days
    
    private init() {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        self.cacheDir = documentsDir.appendingPathComponent("Cache")
        self.importsDir = cacheDir.appendingPathComponent("Imports")
        self.outputDir = cacheDir.appendingPathComponent("Output")
        self.tempDir = fileManager.temporaryDirectory.appendingPathComponent("NativeMusicX")
        
        // Create directories
        try? fileManager.createDirectory(at: importsDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Scan existing files
        scanExistingFiles()
        
        Logger.shared.info("CacheManager initialized: \(cacheDir.path)")
    }
    
    // MARK: - Directory Access
    
    public func getImportsDirectory() -> URL {
        return importsDir
    }
    
    public func getOutputDirectory() -> URL {
        return outputDir
    }
    
    public func getTempDirectory() -> URL {
        return tempDir
    }
    
    // MARK: - File Management
    
    /// Copy imported file to cache with tracking
    public func cacheImportedFile(_ sourceURL: URL) throws -> URL {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = importsDir.appendingPathComponent(fileName)
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Copy file
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        // Track file
        let fileSize = try fileManager.attributesOfItem(atPath: destinationURL.path)[.size] as? UInt64 ?? 0
        let cachedFile = CachedFile(
            url: destinationURL,
            createdAt: Date(),
            category: "import",
            accessedAt: Date(),
            size: fileSize
        )
        
        lock.lock()
        trackedFiles[destinationURL.path] = cachedFile
        lock.unlock()
        
        Logger.shared.info("📥 Cached imported file: \(fileName) (\(formatBytes(fileSize)))")
        
        // Check cache size and cleanup if needed
        cleanupIfNeeded()
        
        return destinationURL
    }
    
    /// Create temporary file with tracking
    public func createTempFile(withExtension ext: String) -> URL {
        let fileName = "temp_\(UUID().uuidString).\(ext)"
        let url = tempDir.appendingPathComponent(fileName)
        
        let cachedFile = CachedFile(
            url: url,
            createdAt: Date(),
            category: "temp",
            accessedAt: Date()
        )
        
        lock.lock()
        trackedFiles[url.path] = cachedFile
        lock.unlock()
        
        return url
    }
    
    /// Track output file
    public func trackOutputFile(_ url: URL) {
        let fileSize = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
        
        let cachedFile = CachedFile(
            url: url,
            createdAt: Date(),
            category: "output",
            accessedAt: Date(),
            size: fileSize ?? 0
        )
        
        lock.lock()
        trackedFiles[url.path] = cachedFile
        lock.unlock()
        
        Logger.shared.info("📤 Tracked output file: \(url.lastPathComponent)")
    }
    
    /// Mark file as accessed (updates access time)
    public func accessFile(_ url: URL) {
        lock.lock()
        if var cachedFile = trackedFiles[url.path] {
            cachedFile.accessedAt = Date()
            trackedFiles[url.path] = cachedFile
        }
        lock.unlock()
    }
    
    // MARK: - Cleanup
    
    private func scanExistingFiles() {
        lock.lock()
        defer { lock.unlock() }
        
        let directories = [importsDir, outputDir, tempDir]
        
        for dir in directories {
            guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else {
                continue
            }
            
            for fileURL in files {
                let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path)
                let size = attrs?[.size] as? UInt64 ?? 0
                let modDate = attrs?[.modificationDate] as? Date ?? Date()
                
                let category: String
                if dir == importsDir { category = "import" }
                else if dir == outputDir { category = "output" }
                else { category = "temp" }
                
                let cachedFile = CachedFile(
                    url: fileURL,
                    createdAt: modDate,
                    category: category,
                    accessedAt: modDate,
                    size: size
                )
                
                trackedFiles[fileURL.path] = cachedFile
            }
        }
        
        Logger.shared.info("📊 Scanned cache: \(trackedFiles.count) files")
    }
    
    private func cleanupIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        
        let totalSize = trackedFiles.values.reduce(0) { $0 + $1.size }
        
        if totalSize > maxCacheSize {
            Logger.shared.warning("⚠️ Cache size exceeded: \(formatBytes(totalSize)) > \(formatBytes(maxCacheSize))")
            performCleanup()
        }
    }
    
    private func performCleanup() {
        let now = Date()
        
        // Remove expired files first
        var filesToRemove: [String] = []
        
        for (path, cachedFile) in trackedFiles {
            let age = now.timeIntervalSince(cachedFile.createdAt)
            
            // Remove temp files older than 1 hour
            if cachedFile.category == "temp" && age > 3600 {
                filesToRemove.append(path)
            }
            
            // Remove old files
            if age > fileExpirationTime {
                filesToRemove.append(path)
            }
        }
        
        // If still over limit, remove oldest files by access time
        if trackedFiles.values.reduce(0, { $0 + $1.size }) > maxCacheSize {
            let sortedByAccess = trackedFiles.sorted { $0.value.accessedAt < $1.value.accessedAt }
            var currentSize = trackedFiles.values.reduce(0) { $0 + $1.size }
            
            for (path, cachedFile) in sortedByAccess {
                if currentSize <= maxCacheSize * 8 / 10 { break } // Stop at 80% capacity
                if !filesToRemove.contains(path) {
                    filesToRemove.append(path)
                    currentSize -= cachedFile.size
                }
            }
        }
        
        // Remove files
        for path in filesToRemove {
            do {
                try fileManager.removeItem(atPath: path)
                trackedFiles.removeValue(forKey: path)
                Logger.shared.info("🗑️ Cleaned up: \(URL(fileURLWithPath: path).lastPathComponent)")
            } catch {
                Logger.shared.warning("⚠️ Failed to remove cache file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Manually clear all temporary files
    public func clearTempFiles() {
        lock.lock()
        defer { lock.unlock() }
        
        let tempFiles = trackedFiles.filter { $0.value.category == "temp" }
        
        for (path, _) in tempFiles {
            try? fileManager.removeItem(atPath: path)
            trackedFiles.removeValue(forKey: path)
        }
        
        Logger.shared.info("🗑️ Cleared \(tempFiles.count) temporary files")
    }
    
    /// Clear all cache
    public func clearAllCache() {
        lock.lock()
        defer { lock.unlock() }
        
        for (path, _) in trackedFiles {
            try? fileManager.removeItem(atPath: path)
        }
        trackedFiles.removeAll()
        
        Logger.shared.info("🗑️ Cleared all cache")
    }
    
    // MARK: - Statistics
    
    public func getCacheStatistics() -> (totalSize: UInt64, fileCount: Int, byCategory: [String: (count: Int, size: UInt64)]) {
        lock.lock()
        defer { lock.unlock() }
        
        var byCategory: [String: (count: Int, size: UInt64)] = [:]
        var totalSize: UInt64 = 0
        
        for (_, cachedFile) in trackedFiles {
            totalSize += cachedFile.size
            
            if byCategory[cachedFile.category] == nil {
                byCategory[cachedFile.category] = (0, 0)
            }
            
            byCategory[cachedFile.category]?.count += 1
            byCategory[cachedFile.category]?.size += cachedFile.size
        }
        
        return (totalSize, trackedFiles.count, byCategory)
    }
    
    public func getCacheReport() -> String {
        let stats = getCacheStatistics()
        
        var report = "=== Cache Report ===\n"
        report += "Total Size: \(formatBytes(stats.totalSize))\n"
        report += "Total Files: \(stats.fileCount)\n"
        report += "By Category:\n"
        
        for (category, info) in stats.byCategory.sorted(by: { $0.key < $1.key }) {
            report += "  • \(category): \(info.count) files (\(formatBytes(info.size)))\n"
        }
        
        return report
    }
    
    // MARK: - Utilities
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
