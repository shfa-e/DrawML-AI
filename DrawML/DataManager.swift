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
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
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
        loadData()
        createDefaultModelIfNeeded()
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
    
    // MARK: - Data Persistence
    
    private func loadData() {
        loadTrainingSamples()
        loadModels()
        loadLabels()
        loadAppSettings()
        loadClassificationHistory()
        loadPlaygroundItems()
    }
    
    private func loadTrainingSamples() {
        if let data = userDefaults.data(forKey: Keys.trainingSamples),
           let samples = try? decoder.decode([TrainingSample].self, from: data) {
            trainingSamples = samples
        }
    }
    
    private func saveTrainingSamples() {
        if let data = try? encoder.encode(trainingSamples) {
            userDefaults.set(data, forKey: Keys.trainingSamples)
        }
    }
    
    private func loadModels() {
        if let data = userDefaults.data(forKey: Keys.models),
           let models = try? decoder.decode([ModelInfo].self, from: data) {
            self.models = models
        }
    }
    
    private func saveModels() {
        if let data = try? encoder.encode(models) {
            userDefaults.set(data, forKey: Keys.models)
        }
    }
    
    private func loadLabels() {
        if let data = userDefaults.data(forKey: Keys.labels),
           let labels = try? decoder.decode([LabelInfo].self, from: data) {
            self.labels = labels
        }
    }
    
    private func saveLabels() {
        if let data = try? encoder.encode(labels) {
            userDefaults.set(data, forKey: Keys.labels)
        }
    }
    
    private func loadAppSettings() {
        if let data = userDefaults.data(forKey: Keys.appSettings),
           let settings = try? decoder.decode(AppSettings.self, from: data) {
            appSettings = settings
        }
    }
    
    private func saveAppSettings() {
        if let data = try? encoder.encode(appSettings) {
            userDefaults.set(data, forKey: Keys.appSettings)
        }
    }
    
    private func loadClassificationHistory() {
        if let data = userDefaults.data(forKey: Keys.classificationHistory),
           let history = try? decoder.decode([ClassificationResult].self, from: data) {
            classificationHistory = history
        }
    }
    
    private func saveClassificationHistory() {
        if let data = try? encoder.encode(classificationHistory) {
            userDefaults.set(data, forKey: Keys.classificationHistory)
        }
    }
    
    private func loadPlaygroundItems() {
        if let data = userDefaults.data(forKey: Keys.playgroundItems),
           let items = try? decoder.decode([PlaygroundItem].self, from: data) {
            playgroundItems = items
        }
    }
    
    private func savePlaygroundItems() {
        if let data = try? encoder.encode(playgroundItems) {
            userDefaults.set(data, forKey: Keys.playgroundItems)
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
        saveTrainingSamples()
        saveModels()
        saveLabels()
        saveAppSettings()
        saveClassificationHistory()
        savePlaygroundItems()
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
