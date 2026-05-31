import Foundation
import CoreML

/// ModelManager handles CoreML model loading and lifecycle.
/// Ensures models are loaded efficiently and compute units are optimized.
public class ModelManager {
    
    static let shared = ModelManager()
    
    private let lock = NSLock()
    private var loadedModels: [String: MLModel] = [:]
    
    public enum ModelType: String {
        case stemSeparation = "Stem Separation"
        case chordDetection = "Chord Detection"
        case beatDetection = "Beat Detection"
    }
    
    private init() {
        Logger.shared.info("ModelManager initialized")
    }
    
    // MARK: - Model Loading
    
    /// Load a CoreML model with specified compute units
    public func loadModel(
        named modelName: String,
        computeUnits: MLComputeUnits = .all
    ) throws -> MLModel {
        lock.lock()
        defer { lock.unlock() }
        
        // Check if already loaded
        if let cachedModel = loadedModels[modelName] {
            Logger.shared.debug("📦 Using cached model: \(modelName)")
            return cachedModel
        }
        
        // Load from bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw NSError(domain: "ModelManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found: \(modelName)"])
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = computeUnits
        
        let model = try MLModel(contentsOf: modelURL, configuration: config)
        loadedModels[modelName] = model
        
        let computeUnitsString: String
        switch computeUnits {
        case .all:
            computeUnitsString = "Neural Engine + GPU + CPU"
        case .cpuAndGPU:
            computeUnitsString = "GPU + CPU"
        case .cpuOnly:
            computeUnitsString = "CPU Only"
        @unknown default:
            computeUnitsString = "Unknown"
        }
        
        Logger.shared.info("🤖 Loaded model: \(modelName) (\(computeUnitsString))")
        return model
    }
    
    /// Get model input/output descriptions
    public func getModelDescription(for modelName: String) throws -> MLModelDescription {
        let model = try loadModel(named: modelName)
        return model.modelDescription
    }
    
    /// Unload a model to free memory
    public func unloadModel(named modelName: String) {
        lock.lock()
        defer { lock.unlock() }
        
        if loadedModels.removeValue(forKey: modelName) != nil {
            Logger.shared.info("🗑️ Unloaded model: \(modelName)")
        }
    }
    
    /// Unload all models
    public func unloadAllModels() {
        lock.lock()
        defer { lock.unlock() }
        
        let count = loadedModels.count
        loadedModels.removeAll()
        Logger.shared.info("🗑️ Unloaded \(count) models")
    }
    
    /// Get list of loaded models
    public func getLoadedModels() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(loadedModels.keys)
    }
    
    // MARK: - Compute Unit Selection
    
    /// Determine optimal compute units based on device capabilities
    public static func getOptimalComputeUnits() -> MLComputeUnits {
        // Prefer Neural Engine (all) for best performance
        // Falls back to CPU+GPU if ANE unavailable
        // Falls back to CPU only if GPU unavailable
        return .all
    }
    
    /// Get compute units for specific model type
    public func getComputeUnits(for modelType: ModelType) -> MLComputeUnits {
        // For stem separation (heavy model), use all available
        // For analysis models, can use CPU+GPU
        switch modelType {
        case .stemSeparation:
            return .all  // Use Neural Engine
        case .chordDetection, .beatDetection:
            return .all  // Use Neural Engine for speed
        }
    }
    
    // MARK: - Model Information
    
    public struct ModelInfo {
        public let name: String
        public let type: ModelType
        public let inputShape: [Int]?
        public let outputShape: [Int]?
        public let estimatedSize: UInt64
        public let isLoaded: Bool
    }
    
    /// Get information about available models
    public func getAvailableModels() -> [ModelInfo] {
        var models: [ModelInfo] = []
        
        // Stem separation models
        let stemModels = [
            "dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1",
            "dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0"
        ]
        
        for modelName in stemModels {
            let isLoaded = lock.withLock { loadedModels[modelName] != nil }
            models.append(ModelInfo(
                name: modelName,
                type: .stemSeparation,
                inputShape: [1, 4, 32, 2048],
                outputShape: [1, 4, 32, 2048],
                estimatedSize: modelName.contains("fp16") ? 250 * 1024 * 1024 : 500 * 1024 * 1024,
                isLoaded: isLoaded
            ))
        }
        
        // Analysis models
        let analysisModels = [
            ("Chordcrnn", ModelType.chordDetection, 50 * 1024 * 1024),
            ("convtcn20_2048_fp16", ModelType.beatDetection, 30 * 1024 * 1024)
        ]
        
        for (modelName, type, size) in analysisModels {
            let isLoaded = lock.withLock { loadedModels[modelName] != nil }
            models.append(ModelInfo(
                name: modelName,
                type: type,
                inputShape: nil,
                outputShape: nil,
                estimatedSize: size,
                isLoaded: isLoaded
            ))
        }
        
        return models
    }
    
    /// Get total memory used by loaded models
    public func getTotalModelMemory() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        
        var totalMemory: UInt64 = 0
        for modelName in loadedModels.keys {
            // Estimate based on model name
            if modelName.contains("fp16") {
                totalMemory += 250 * 1024 * 1024
            } else if modelName.contains("dun") {
                totalMemory += 500 * 1024 * 1024
            } else {
                totalMemory += 50 * 1024 * 1024
            }
        }
        return totalMemory
    }
}

// MARK: - Helper Extension

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
