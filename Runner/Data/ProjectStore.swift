import Foundation

/// ProjectStore manages local persistence of StemProject data.
/// Stores projects in Documents directory with JSON encoding.
public class ProjectStore {
    
    static let shared = ProjectStore()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()
    
    private let projectsDirectory: URL
    
    private init() {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.projectsDirectory = documentsDir.appendingPathComponent("Projects")
        
        // Create projects directory
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
        
        // Setup date formatting for JSON
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        Logger.shared.info("ProjectStore initialized: \(projectsDirectory.path)")
    }
    
    // MARK: - Save/Load
    
    /// Save a project to disk
    public func saveProject(_ project: StemProject) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let projectFile = projectsDirectory.appendingPathComponent("\(project.id).json")
        
        let data = try encoder.encode(project)
        try data.write(to: projectFile)
        
        Logger.shared.info("💾 Saved project: \(project.name) (\(project.id))")
    }
    
    /// Load a project from disk
    public func loadProject(withId id: String) throws -> StemProject {
        lock.lock()
        defer { lock.unlock() }
        
        let projectFile = projectsDirectory.appendingPathComponent("\(id).json")
        
        guard fileManager.fileExists(atPath: projectFile.path) else {
            throw NSError(domain: "ProjectStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Project not found: \(id)"])
        }
        
        let data = try Data(contentsOf: projectFile)
        let project = try decoder.decode(StemProject.self, from: data)
        
        Logger.shared.info("📂 Loaded project: \(project.name)")
        return project
    }
    
    /// Load all projects
    public func loadAllProjects() throws -> [StemProject] {
        lock.lock()
        defer { lock.unlock() }
        
        let files = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        
        var projects: [StemProject] = []
        for file in jsonFiles {
            do {
                let data = try Data(contentsOf: file)
                let project = try decoder.decode(StemProject.self, from: data)
                projects.append(project)
            } catch {
                Logger.shared.warning("⚠️ Failed to load project from \(file.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        Logger.shared.info("📂 Loaded \(projects.count) projects")
        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// Delete a project
    public func deleteProject(withId id: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let projectFile = projectsDirectory.appendingPathComponent("\(id).json")
        
        guard fileManager.fileExists(atPath: projectFile.path) else {
            throw NSError(domain: "ProjectStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Project not found: \(id)"])
        }
        
        try fileManager.removeItem(at: projectFile)
        Logger.shared.info("🗑️ Deleted project: \(id)")
    }
    
    /// Check if project exists
    public func projectExists(withId id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let projectFile = projectsDirectory.appendingPathComponent("\(id).json")
        return fileManager.fileExists(atPath: projectFile.path)
    }
    
    // MARK: - Utilities
    
    /// Get project file size
    public func getProjectSize(withId id: String) throws -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        
        let projectFile = projectsDirectory.appendingPathComponent("\(id).json")
        let attributes = try fileManager.attributesOfItem(atPath: projectFile.path)
        return attributes[.size] as? UInt64 ?? 0
    }
    
    /// Get total storage used by all projects
    public func getTotalStorageUsed() throws -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        
        let files = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: [.fileSizeKey])
        var totalSize: UInt64 = 0
        
        for file in files {
            let attributes = try fileManager.attributesOfItem(atPath: file.path)
            totalSize += attributes[.size] as? UInt64 ?? 0
        }
        
        return totalSize
    }
    
    /// Export project as JSON
    public func exportProject(_ project: StemProject, to url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let data = try encoder.encode(project)
        try data.write(to: url)
        
        Logger.shared.info("📤 Exported project to: \(url.lastPathComponent)")
    }
    
    /// Import project from JSON
    public func importProject(from url: URL) throws -> StemProject {
        lock.lock()
        defer { lock.unlock() }
        
        let data = try Data(contentsOf: url)
        let project = try decoder.decode(StemProject.self, from: data)
        
        // Save to local store
        try? fileManager.removeItem(at: projectsDirectory.appendingPathComponent("\(project.id).json"))
        let projectFile = projectsDirectory.appendingPathComponent("\(project.id).json")
        try data.write(to: projectFile)
        
        Logger.shared.info("📥 Imported project: \(project.name)")
        return project
    }
    
    /// Get projects directory URL
    public func getProjectsDirectory() -> URL {
        return projectsDirectory
    }
    
    /// Clear all projects
    public func clearAllProjects() throws {
        lock.lock()
        defer { lock.unlock() }
        
        let files = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }
        
        Logger.shared.info("🗑️ Cleared all projects")
    }
}
