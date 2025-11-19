//
//  DataManager.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var trainingSamples: [TrainingSample] = []
    @Published var models: [ModelInfo] = []
    @Published var labels: [LabelInfo] = []
    @Published var appSettings: AppSettings = AppSettings()
    @Published var classificationHistory: [ClassificationResult] = []
    @Published var playgroundItems: [PlaygroundItem] = []
    
    // Data persistence state
    @Published var lastSaveError: String?
    @Published var lastLoadError: String?
    @Published var isSaving = false
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    private lazy var playgroundItemsFileURL: URL = {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = baseDirectory.appendingPathComponent("PlaygroundCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create playground cache directory: \(error)")
            }
        }
        
        return folderURL.appendingPathComponent("playground_items.json")
    }()
    
    // Data version for migration
    private let currentDataVersion = 1
    private let dataVersionKey = "dataVersion"
    
    // Keys for UserDefaults
    private enum Keys {
        static let trainingSamples = "trainingSamples"
        static let models = "models"
        static let labels = "labels"
        static let appSettings = "appSettings"
        static let classificationHistory = "classificationHistory"
        static let playgroundItems = "playgroundItems"
    }
    
    private init() {
        setupEncoder()
        performDataMigration()
        loadData()
        createDefaultModelIfNeeded()
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Training Samples Management
    
    func addTrainingSample(_ sample: TrainingSample) -> Bool {
        // Validate the sample
        guard DataValidator.validateTrainingSample(sample) else {
            return false
        }
        
        // Add to array
        trainingSamples.append(sample)
        
        // Update labels
        updateLabelForSample(sample)
        
        // Save to persistent storage
        saveTrainingSamples()
        
        return true
    }
    
    func removeTrainingSample(_ sample: TrainingSample) {
        trainingSamples.removeAll { $0.id == sample.id }
        updateLabelsForModel(sample.modelId)
        saveTrainingSamples()
    }
    
    func getTrainingSamples(for modelId: UUID) -> [TrainingSample] {
        return trainingSamples.filter { $0.modelId == modelId }
    }
    
    func getTrainingSamples(for emoji: String, modelId: UUID) -> [TrainingSample] {
        return trainingSamples.filter { $0.emoji == emoji && $0.modelId == modelId }
    }
    
    // MARK: - Models Management
    
    func addModel(_ model: ModelInfo) -> Bool {
        guard DataValidator.validateModelInfo(model) else {
            return false
        }
        
        // If this is the first model or it's marked as active, deactivate others
        if models.isEmpty || model.isActive {
            deactivateAllModels()
        }
        
        models.append(model)
        saveModels()
        return true
    }
    
    func updateModel(_ model: ModelInfo) -> Bool {
        guard DataValidator.validateModelInfo(model) else {
            return false
        }
        
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            models[index] = model
            saveModels()
            return true
        }
        
        return false
    }
    
    func removeModel(_ model: ModelInfo) {
        // Remove all training samples for this model
        trainingSamples.removeAll { $0.modelId == model.id }
        
        // Remove all labels for this model
        labels.removeAll { $0.modelId == model.id }
        
        // Remove the model
        models.removeAll { $0.id == model.id }
        
        // If this was the active model, activate another one
        if model.isActive && !models.isEmpty {
            models[0] = ModelInfo(
                id: models[0].id,
                name: models[0].name,
                createdDate: models[0].createdDate,
                lastTrained: models[0].lastTrained,
                isActive: true
            )
        }
        
        saveModels()
        saveTrainingSamples()
        saveLabels()
    }
    
    func getActiveModel() -> ModelInfo? {
        return models.first { $0.isActive }
    }
    
    func hasTrainedModel(for modelId: UUID) -> Bool {
        return ModelTrainingManager.shared.hasTrainedModel(for: modelId)
    }
    
    func setActiveModel(_ model: ModelInfo) {
        deactivateAllModels()
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            models[index] = ModelInfo(
                id: model.id,
                name: model.name,
                createdDate: model.createdDate,
                lastTrained: model.lastTrained,
                isActive: true
            )
            saveModels()
        }
    }
    
    private func deactivateAllModels() {
        for i in 0..<models.count {
            models[i] = ModelInfo(
                id: models[i].id,
                name: models[i].name,
                createdDate: models[i].createdDate,
                lastTrained: models[i].lastTrained,
                isActive: false
            )
        }
    }
    
    // MARK: - Labels Management
    
    func updateLabelForSample(_ sample: TrainingSample) {
        let existingLabel = labels.first { $0.emoji == sample.emoji && $0.modelId == sample.modelId }
        
        if let existingLabel = existingLabel {
            // Update existing label
            let newSampleCount = getTrainingSamples(for: sample.emoji, modelId: sample.modelId).count
            if let index = labels.firstIndex(where: { $0.id == existingLabel.id }) {
                labels[index] = LabelInfo(
                    id: existingLabel.id,
                    emoji: existingLabel.emoji,
                    name: existingLabel.name,
                    sampleCount: newSampleCount,
                    modelId: existingLabel.modelId
                )
            }
        } else {
            // Create new label
            let newLabel = LabelInfo(
                emoji: sample.emoji,
                sampleCount: 1,
                modelId: sample.modelId
            )
            labels.append(newLabel)
        }
        
        saveLabels()
    }
    
    func updateLabelsForModel(_ modelId: UUID) {
        // Remove labels for this model
        labels.removeAll { $0.modelId == modelId }
        
        // Recreate labels based on current samples
        let modelSamples = getTrainingSamples(for: modelId)
        let emojiGroups = Dictionary(grouping: modelSamples) { $0.emoji }
        
        for (emoji, samples) in emojiGroups {
            let label = LabelInfo(
                emoji: emoji,
                sampleCount: samples.count,
                modelId: modelId
            )
            labels.append(label)
        }
        
        saveLabels()
    }
    
    func getLabels(for modelId: UUID) -> [LabelInfo] {
        return labels.filter { $0.modelId == modelId }
    }
    
    // MARK: - App Settings Management
    
    func updateAppSettings(_ settings: AppSettings) {
        appSettings = settings
        saveAppSettings()
    }
    
    // MARK: - Classification History Management
    
    func addClassificationResult(_ result: ClassificationResult) {
        classificationHistory.append(result)
        
        // Keep only last 50 results
        if classificationHistory.count > 50 {
            classificationHistory = Array(classificationHistory.suffix(50))
        }
        
        saveClassificationHistory()
    }
    
    func getClassificationHistory(for modelId: UUID) -> [ClassificationResult] {
        return classificationHistory.filter { $0.modelId == modelId }
    }
    
    // MARK: - Playground Items Management
    
    func addPlaygroundItem(_ item: PlaygroundItem) {
        playgroundItems.append(item)
        savePlaygroundItems()
    }
    
    func removePlaygroundItem(_ item: PlaygroundItem) {
        playgroundItems.removeAll { $0.id == item.id }
        savePlaygroundItems()
    }
    
    func clearPlaygroundItems() {
        playgroundItems.removeAll()
        savePlaygroundItems()
    }
    
    // MARK: - Data Migration
    
    private func performDataMigration() {
        let storedVersion = userDefaults.integer(forKey: dataVersionKey)
        
        if storedVersion < currentDataVersion {
            print("Performing data migration from version \(storedVersion) to \(currentDataVersion)")
            
            // Future migration logic can be added here
            // For now, we just update the version
            userDefaults.set(currentDataVersion, forKey: dataVersionKey)
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        isLoading = true
        lastLoadError = nil
        
        do {
            try loadTrainingSamples()
            try loadModels()
            try loadLabels()
            try loadAppSettings()
            try loadClassificationHistory()
            try loadPlaygroundItems()
            
            print("Data loaded successfully")
        } catch {
            lastLoadError = "Failed to load data: \(error.localizedDescription)"
            print("Data loading error: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadTrainingSamples() throws {
        guard let data = userDefaults.data(forKey: Keys.trainingSamples) else {
            return // No data to load
        }
        
        do {
            let samples = try decoder.decode([TrainingSample].self, from: data)
            trainingSamples = samples
        } catch {
            print("Failed to decode training samples: \(error)")
            // Try to recover by loading an empty array
            trainingSamples = []
        }
    }
    
    private func saveTrainingSamples() {
        do {
            let data = try encoder.encode(trainingSamples)
            userDefaults.set(data, forKey: Keys.trainingSamples)
            print("Training samples saved successfully")
        } catch {
            lastSaveError = "Failed to save training samples: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func loadModels() throws {
        guard let data = userDefaults.data(forKey: Keys.models) else {
            return // No data to load
        }
        
        do {
            let models = try decoder.decode([ModelInfo].self, from: data)
            self.models = models
        } catch {
            print("Failed to decode models: \(error)")
            // Try to recover by loading an empty array
            self.models = []
        }
    }
    
    private func saveModels() {
        do {
            let data = try encoder.encode(models)
            userDefaults.set(data, forKey: Keys.models)
            print("Models saved successfully")
        } catch {
            lastSaveError = "Failed to save models: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func loadLabels() throws {
        guard let data = userDefaults.data(forKey: Keys.labels) else {
            return // No data to load
        }
        
        do {
            let labels = try decoder.decode([LabelInfo].self, from: data)
            self.labels = labels
        } catch {
            print("Failed to decode labels: \(error)")
            // Try to recover by loading an empty array
            self.labels = []
        }
    }
    
    private func saveLabels() {
        do {
            let data = try encoder.encode(labels)
            userDefaults.set(data, forKey: Keys.labels)
            print("Labels saved successfully")
        } catch {
            lastSaveError = "Failed to save labels: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func loadAppSettings() throws {
        guard let data = userDefaults.data(forKey: Keys.appSettings) else {
            return // No data to load, use defaults
        }
        
        do {
            let settings = try decoder.decode(AppSettings.self, from: data)
            appSettings = settings
        } catch {
            print("Failed to decode app settings: \(error)")
            // Use default settings
            appSettings = AppSettings()
        }
    }
    
    private func saveAppSettings() {
        do {
            let data = try encoder.encode(appSettings)
            userDefaults.set(data, forKey: Keys.appSettings)
            print("App settings saved successfully")
        } catch {
            lastSaveError = "Failed to save app settings: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func loadClassificationHistory() throws {
        guard let data = userDefaults.data(forKey: Keys.classificationHistory) else {
            return // No data to load
        }
        
        do {
            let history = try decoder.decode([ClassificationResult].self, from: data)
            classificationHistory = history
        } catch {
            print("Failed to decode classification history: \(error)")
            // Try to recover by loading an empty array
            classificationHistory = []
        }
    }
    
    private func saveClassificationHistory() {
        do {
            let data = try encoder.encode(classificationHistory)
            userDefaults.set(data, forKey: Keys.classificationHistory)
            print("Classification history saved successfully")
        } catch {
            lastSaveError = "Failed to save classification history: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    private func loadPlaygroundItems() throws {
        // Prefer disk cache, fall back to UserDefaults for legacy data
        if fileManager.fileExists(atPath: playgroundItemsFileURL.path) {
            do {
                let data = try Data(contentsOf: playgroundItemsFileURL)
                let items = try decoder.decode([PlaygroundItem].self, from: data)
                playgroundItems = items
                // Keep UserDefaults copy in sync for export/backups
                userDefaults.set(data, forKey: Keys.playgroundItems)
                return
            } catch {
                print("Failed to load playground items from disk: \(error)")
            }
        }
        
        guard let data = userDefaults.data(forKey: Keys.playgroundItems) else {
            playgroundItems = []
            return
        }
        
        do {
            let items = try decoder.decode([PlaygroundItem].self, from: data)
            playgroundItems = items
            
            // Seed disk cache for future launches
            try data.write(to: playgroundItemsFileURL, options: .atomic)
        } catch {
            print("Failed to decode playground items: \(error)")
            playgroundItems = []
        }
    }
    
    private func savePlaygroundItems() {
        do {
            let data = try encoder.encode(playgroundItems)
            try data.write(to: playgroundItemsFileURL, options: .atomic)
            userDefaults.set(data, forKey: Keys.playgroundItems)
            print("Playground items saved to disk")
        } catch {
            lastSaveError = "Failed to save playground items: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
    
    // MARK: - Default Data
    
    private func createDefaultModelIfNeeded() {
        if models.isEmpty {
            let defaultModel = ModelInfo(
                name: "My First Model",
                isActive: true
            )
            _ = addModel(defaultModel)
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportData() -> Data? {
        let exportData = ExportData(
            trainingSamples: trainingSamples,
            models: models,
            labels: labels,
            appSettings: appSettings,
            classificationHistory: classificationHistory,
            playgroundItems: playgroundItems
        )
        
        return try? encoder.encode(exportData)
    }
    
    func importData(_ data: Data) -> Bool {
        guard let importData = try? decoder.decode(ExportData.self, from: data) else {
            return false
        }
        
        trainingSamples = importData.trainingSamples
        models = importData.models
        labels = importData.labels
        appSettings = importData.appSettings
        classificationHistory = importData.classificationHistory
        playgroundItems = importData.playgroundItems
        
        saveData()
        return true
    }
    
    private func saveData() {
        isSaving = true
        lastSaveError = nil
        
        saveTrainingSamples()
        saveModels()
        saveLabels()
        saveAppSettings()
        saveClassificationHistory()
        savePlaygroundItems()
        
        isSaving = false
    }
    
    // MARK: - Data Backup and Restore
    
    func createBackup() -> Data? {
        let backupData = BackupData(
            version: currentDataVersion,
            timestamp: Date(),
            trainingSamples: trainingSamples,
            models: models,
            labels: labels,
            appSettings: appSettings,
            classificationHistory: classificationHistory,
            playgroundItems: playgroundItems
        )
        
        do {
            let data = try encoder.encode(backupData)
            print("Backup created successfully")
            return data
        } catch {
            lastSaveError = "Failed to create backup: \(error.localizedDescription)"
            print("Backup creation error: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(_ data: Data) -> Bool {
        do {
            let backupData = try decoder.decode(BackupData.self, from: data)
            
            // Validate backup version
            guard backupData.version <= currentDataVersion else {
                lastLoadError = "Backup is from a newer version and cannot be restored"
                return false
            }
            
            // Restore data
            trainingSamples = backupData.trainingSamples
            models = backupData.models
            labels = backupData.labels
            appSettings = backupData.appSettings
            classificationHistory = backupData.classificationHistory
            playgroundItems = backupData.playgroundItems
            
            // Save restored data
            saveData()
            
            print("Data restored from backup successfully")
            return true
            
        } catch {
            lastLoadError = "Failed to restore from backup: \(error.localizedDescription)"
            print("Backup restoration error: \(error)")
            return false
        }
    }
    
    func clearAllData() {
        trainingSamples.removeAll()
        models.removeAll()
        labels.removeAll()
        appSettings = AppSettings()
        classificationHistory.removeAll()
        playgroundItems.removeAll()
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: Keys.trainingSamples)
        userDefaults.removeObject(forKey: Keys.models)
        userDefaults.removeObject(forKey: Keys.labels)
        userDefaults.removeObject(forKey: Keys.appSettings)
        userDefaults.removeObject(forKey: Keys.classificationHistory)
        userDefaults.removeObject(forKey: Keys.playgroundItems)
        if fileManager.fileExists(atPath: playgroundItemsFileURL.path) {
            do {
                try fileManager.removeItem(at: playgroundItemsFileURL)
            } catch {
                print("Failed to remove playground cache: \(error)")
            }
        }
        
        // Create default model
        createDefaultModelIfNeeded()
        
        print("All data cleared")
    }
    
    func getDataSize() -> String {
        var totalSize: Int64 = 0
        
        // Calculate UserDefaults data size
        let keys = [Keys.trainingSamples, Keys.models, Keys.labels, Keys.appSettings, Keys.classificationHistory, Keys.playgroundItems]
        for key in keys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += Int64(data.count)
            }
        }
        
        // Calculate model files size
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for model in models {
            let modelURL = documentsPath.appendingPathComponent("model_\(model.id.uuidString).mlmodelc")
            if fileManager.fileExists(atPath: modelURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: modelURL.path)
                    if let size = attributes[.size] as? Int64 {
                        totalSize += size
                    }
                } catch {
                    print("Error calculating model file size: \(error)")
                }
            }
        }
        
        if fileManager.fileExists(atPath: playgroundItemsFileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: playgroundItemsFileURL.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            } catch {
                print("Error calculating playground cache size: \(error)")
            }
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Export Data Structure
struct ExportData: Codable {
    let trainingSamples: [TrainingSample]
    let models: [ModelInfo]
    let labels: [LabelInfo]
    let appSettings: AppSettings
    let classificationHistory: [ClassificationResult]
    let playgroundItems: [PlaygroundItem]
}

// MARK: - Backup Data Structure
struct BackupData: Codable {
    let version: Int
    let timestamp: Date
    let trainingSamples: [TrainingSample]
    let models: [ModelInfo]
    let labels: [LabelInfo]
    let appSettings: AppSettings
    let classificationHistory: [ClassificationResult]
    let playgroundItems: [PlaygroundItem]
}
