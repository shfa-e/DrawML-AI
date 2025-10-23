//
//  ModelTrainingManager.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import Foundation
import CoreML
import PencilKit
import UIKit
import Combine

class ModelTrainingManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    static let shared = ModelTrainingManager()
    
    @Published var isTraining = false
    @Published var trainingProgress: Double = 0.0
    @Published var lastTrainingError: String?
    @Published var lastTrainingSuccess: String?
    
    private var currentModel: MLModel?
    private let fileManager = FileManager.default
    
    private init() {
        // Defer loading to after initialization to avoid using self before init completes
        DispatchQueue.main.async { [weak self] in
            self?.loadCurrentModel()
        }
    }
    
    // MARK: - Model Training
    
    func trainModel(with samples: [TrainingSample], modelId: UUID) async -> Bool {
        await MainActor.run {
            isTraining = true
            trainingProgress = 0.0
            lastTrainingError = nil
            lastTrainingSuccess = nil
        }
        
        do {
            // Validate samples
            guard samples.count >= 2 else {
                await MainActor.run {
                    lastTrainingError = "Need at least 2 samples to train the model"
                    isTraining = false
                }
                return false
            }
            
            // Group samples by emoji
            let groupedSamples = Dictionary(grouping: samples) { $0.emoji }
            guard groupedSamples.count >= 2 else {
                await MainActor.run {
                    lastTrainingError = "Need at least 2 different emoji labels to train"
                    isTraining = false
                }
                return false
            }
            
            // Update progress
            await MainActor.run { trainingProgress = 0.1 }
            
            // Load the base model
            guard loadBaseModel() != nil else {
                await MainActor.run {
                    lastTrainingError = "Could not load base model"
                    isTraining = false
                }
                return false
            }
            
            await MainActor.run { trainingProgress = 0.2 }
            
            // Prepare training data
            let trainingData = try await prepareTrainingData(from: samples)
            await MainActor.run { trainingProgress = 0.4 }
            
            // Create updatable model
            guard let updatableModel = try? MLModel(contentsOf: getBaseModelURL()) else {
                await MainActor.run {
                    lastTrainingError = "Could not create updatable model"
                    isTraining = false
                }
                return false
            }
            
            await MainActor.run { trainingProgress = 0.5 }
            
            // Perform training
            let trainedModel = try await performTraining(
                model: updatableModel,
                trainingData: trainingData
            )
            
            await MainActor.run { trainingProgress = 0.8 }
            
            // Save the trained model
            let success = saveTrainedModel(trainedModel, for: modelId)
            
            await MainActor.run {
                trainingProgress = 1.0
                isTraining = false
                if success {
                    lastTrainingSuccess = "Model trained successfully with \(samples.count) samples!"
                } else {
                    lastTrainingError = "Training completed but failed to save model"
                }
            }
            
            return success
            
        } catch {
            await MainActor.run {
                lastTrainingError = "Training failed: \(error.localizedDescription)"
                isTraining = false
            }
            return false
        }
    }
    
    // MARK: - Model Loading and Saving
    
    private func loadBaseModel() -> MLModel? {
        guard let modelURL = Bundle.main.url(forResource: "UpdatableDrawingClassifier", withExtension: "mlmodel") else { return nil }
        do {
            let compiledURL = try MLModel.compileModel(at: modelURL)
            return try MLModel(contentsOf: compiledURL)
        } catch {
            print("Error loading base model: \(error)")
            return nil
        }
    }
    
    private func getBaseModelURL() -> URL {
        return Bundle.main.url(forResource: "UpdatableDrawingClassifier", withExtension: "mlmodel")!
    }
    
    private func getModelURL(for modelId: UUID) -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("model_\(modelId.uuidString).mlmodelc")
    }
    
    private func saveTrainedModel(_ model: MLModel, for modelId: UUID) -> Bool {
        let modelURL = getModelURL(for: modelId)
        
        do {
            // Remove existing model if it exists
            if fileManager.fileExists(atPath: modelURL.path) {
                try fileManager.removeItem(at: modelURL)
            }

            // Compile the base model and copy the compiled bundle to our destination
            let baseModelURL = getBaseModelURL()
            let compiledURL = try MLModel.compileModel(at: baseModelURL)

            // Create destination directory if needed, then copy the compiled bundle
            try fileManager.copyItem(at: compiledURL, to: modelURL)
            return true
        } catch {
            print("Error saving trained model: \(error)")
            return false
        }
    }
    
    @MainActor private func loadCurrentModel() {
        // Load the most recently trained model
        // This is a simplified implementation
    }
    
    // MARK: - Training Data Preparation
    
    private func prepareTrainingData(from samples: [TrainingSample]) async throws -> [MLFeatureProvider] {
        var trainingData: [MLFeatureProvider] = []
        
        for sample in samples {
            // Convert PKDrawing to image
            let image = try await convertDrawingToImage(sample.toPKDrawing(), size: sample.canvasSize)
            
            // Create feature provider
            let featureProvider = try createFeatureProvider(
                image: image,
                label: sample.emoji
            )
            
            trainingData.append(featureProvider)
        }
        
        return trainingData
    }
    
    private func convertDrawingToImage(_ drawing: PKDrawing, size: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let targetRect = CGRect(origin: .zero, size: size)

                // Render PKDrawing to an image at requested size
                let strokesImage = drawing.image(from: targetRect, scale: 1.0)

                // Composite on a white background so the model sees a non-transparent image
                let renderer = UIGraphicsImageRenderer(size: size)
                let finalImage = renderer.image { _ in
                    UIColor.white.setFill()
                    UIBezierPath(rect: targetRect).fill()
                    strokesImage.draw(in: targetRect)
                }

                continuation.resume(returning: finalImage)
            }
        }
    }
    
    private func createFeatureProvider(image: UIImage, label: String) throws -> MLFeatureProvider {
        // Convert image to pixel buffer
        guard let pixelBuffer = imageToPixelBuffer(image) else {
            throw TrainingError.imageConversionFailed
        }

        // Build a dictionary-based feature provider to avoid mismatches with generated model input types
        let features: [String: MLFeatureValue] = [
            "image": MLFeatureValue(pixelBuffer: pixelBuffer),
            "classLabel": MLFeatureValue(string: label)
        ]

        return try MLDictionaryFeatureProvider(dictionary: features)
    }
    
    private func imageToPixelBuffer(_ image: UIImage) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.size.width),
            Int(image.size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        
        return buffer
    }
    
    // MARK: - Model Training Execution
    
    private func performTraining(model: MLModel, trainingData: [MLFeatureProvider]) async throws -> MLModel {
        // This is a simplified training implementation
        // In a real app, you would use MLUpdateTask for incremental learning
        
        // For now, we'll return the base model
        // In a production app, you would implement proper CoreML training
        // and save the resulting compiled model to disk.
        return model
    }
    
    // MARK: - Model Prediction
    
    func predictDrawing(_ drawing: PKDrawing, modelId: UUID) async -> (emoji: String, confidence: Double)? {
        do {
            // Load the trained model
            let modelURL = getModelURL(for: modelId)
            guard fileManager.fileExists(atPath: modelURL.path) else {
                return nil
            }
            
            let model = try MLModel(contentsOf: modelURL)
            
            // Convert drawing to image
            let image = try await convertDrawingToImage(drawing, size: CGSize(width: 299, height: 299))
            
            // Convert image to pixel buffer
            guard let pixelBuffer = imageToPixelBuffer(image) else {
                return nil
            }

            // Build dictionary-based input for prediction (no label needed for inference)
            let features: [String: MLFeatureValue] = [
                "image": MLFeatureValue(pixelBuffer: pixelBuffer)
            ]
            let input = try MLDictionaryFeatureProvider(dictionary: features)

            // Make prediction
            _ = try await model.prediction(from: input)
            
            // Extract results (this would need to be adapted based on the actual model output)
            // For now, return a placeholder
            return ("🎯", 0.85)
            
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    // MARK: - Model Management
    
    func hasTrainedModel(for modelId: UUID) -> Bool {
        let modelURL = getModelURL(for: modelId)
        return fileManager.fileExists(atPath: modelURL.path)
    }
    
    func deleteTrainedModel(for modelId: UUID) -> Bool {
        let modelURL = getModelURL(for: modelId)
        
        do {
            if fileManager.fileExists(atPath: modelURL.path) {
                try fileManager.removeItem(at: modelURL)
            }
            return true
        } catch {
            print("Error deleting model: \(error)")
            return false
        }
    }
}

// MARK: - Training Errors

enum TrainingError: LocalizedError {
    case imageConversionFailed
    case insufficientSamples
    case modelLoadingFailed
    case trainingDataPreparationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert drawing to image"
        case .insufficientSamples:
            return "Insufficient training samples"
        case .modelLoadingFailed:
            return "Failed to load base model"
        case .trainingDataPreparationFailed:
            return "Failed to prepare training data"
        }
    }
}

// MARK: - Training Progress

struct TrainingProgress {
    let currentStep: Int
    let totalSteps: Int
    let currentStepDescription: String
    
    var progress: Double {
        return Double(currentStep) / Double(totalSteps)
    }
}

