//
//  DataModels.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import Foundation
import PencilKit
import CoreML
import UIKit

// MARK: - Training Sample (D-003)
struct TrainingSample: Identifiable, Codable {
    let id: UUID
    let modelId: UUID
    let emoji: String
    let strokes: [StrokeData]
    let canvasSize: CGSize
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        modelId: UUID,
        emoji: String,
        drawing: PKDrawing,
        canvasSize: CGSize,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.modelId = modelId
        self.emoji = emoji
        self.strokes = drawing.strokes.map { StrokeData(from: $0) }
        self.canvasSize = canvasSize
        self.timestamp = timestamp
    }
    
    func toPKDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        for strokeData in strokes {
            drawing.strokes.append(strokeData.toPKStroke())
        }
        return drawing
    }
}

// MARK: - Stroke Data
struct StrokeData: Codable {
    let points: [PointData]
    let ink: InkData
    let transform: TransformData
    
    init(from stroke: PKStroke) {
        // Precompute simple properties to help the type checker
        let strokeInk: PKInk = stroke.ink
        let strokeTransform: CGAffineTransform = stroke.transform

        // Collect control points by iterating the path (PKStrokePath has no `controlPoints` accessor)
        var collectedPoints: [PKStrokePoint] = []
        stroke.path.forEach { point in
            collectedPoints.append(point)
        }

        // Map collected points to serializable point data with explicit types
        self.points = collectedPoints.map { point in
            let loc: CGPoint = point.location
            let x = Double(loc.x)
            let y = Double(loc.y)
            let pressure = Double(point.force)
            let azimuth = Double(point.azimuth)
            let altitude = Double(point.altitude)
            return PointData(x: x, y: y, pressure: pressure, azimuth: azimuth, altitude: altitude)
        }

        // Serialize ink and transform
        self.ink = InkData(from: strokeInk)
        self.transform = TransformData(from: strokeTransform)
    }
    
    func toPKStroke() -> PKStroke {
        let controlPoints: [PKStrokePoint] = points.map { point in
            let location = CGPoint(x: point.x, y: point.y)
            let size = CGSize(width: 2.0, height: 2.0)
            let timeOffset: CGFloat = 0.0
            let opacity: CGFloat = 1.0
            let force = CGFloat(point.pressure)
            let azimuth = CGFloat(point.azimuth)
            let altitude = CGFloat(point.altitude)
            return PKStrokePoint(
                location: location,
                timeOffset: timeOffset,
                size: size,
                opacity: opacity,
                force: force,
                azimuth: azimuth,
                altitude: altitude
            )
        }

        let creationDate = Date()
        let path = PKStrokePath(controlPoints: controlPoints, creationDate: creationDate)

        let inkType = ink.inkType
        let uiColor = ink.color.toUIColor()
        let pkInk = PKInk(inkType, color: uiColor)

        let t = self.transform
        let cgTransform = CGAffineTransform(
            a: CGFloat(t.a), b: CGFloat(t.b),
            c: CGFloat(t.c), d: CGFloat(t.d),
            tx: CGFloat(t.tx), ty: CGFloat(t.ty)
        )

        return PKStroke(ink: pkInk, path: path, transform: cgTransform)
    }
}

// MARK: - Point Data
struct PointData: Codable, Equatable {
    let x: Double
    let y: Double
    let pressure: Double
    let azimuth: Double
    let altitude: Double
}

// MARK: - Ink Data
struct InkData: Codable {
    let inkTypeRawValue: String
    let color: ColorData
    
    var inkType: PKInk.InkType {
        return PKInk.InkType(rawValue: inkTypeRawValue) ?? .pen
    }
    
    init(from ink: PKInk) {
        self.inkTypeRawValue = ink.inkType.rawValue
        self.color = ColorData(from: ink.color)
    }
}

// MARK: - Color Data
struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(from color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }
    
    func toUIColor() -> UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}

// MARK: - Transform Data
struct TransformData: Codable {
    let a: Double
    let b: Double
    let c: Double
    let d: Double
    let tx: Double
    let ty: Double
    
    init(from transform: CGAffineTransform) {
        self.a = Double(transform.a)
        self.b = Double(transform.b)
        self.c = Double(transform.c)
        self.d = Double(transform.d)
        self.tx = Double(transform.tx)
        self.ty = Double(transform.ty)
    }
}

// MARK: - Mask Data (simplified for now)
struct MaskData: Codable {
    let imageData: Data
    
    init() {
        self.imageData = Data()
    }
}

// MARK: - Model List (D-001)
struct ModelInfo: Identifiable, Codable {
    let id: UUID
    let name: String
    let createdDate: Date
    let lastTrained: Date?
    let isActive: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        createdDate: Date = Date(),
        lastTrained: Date? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.lastTrained = lastTrained
        self.isActive = isActive
    }
}

// MARK: - Labels (D-002)
struct LabelInfo: Identifiable, Codable {
    let id: UUID
    let emoji: String
    let name: String?
    let sampleCount: Int
    let modelId: UUID
    
    init(
        id: UUID = UUID(),
        emoji: String,
        name: String? = nil,
        sampleCount: Int = 0,
        modelId: UUID
    ) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.sampleCount = sampleCount
        self.modelId = modelId
    }
}

// MARK: - App Settings (D-005)
struct AppSettings: Codable {
    var darkMode: Bool
    var onboardingSeen: Bool
    var penSize: Double
    var lastActiveModelId: UUID?
    
    init(
        darkMode: Bool = false,
        onboardingSeen: Bool = false,
        penSize: Double = 2.0,
        lastActiveModelId: UUID? = nil
    ) {
        self.darkMode = darkMode
        self.onboardingSeen = onboardingSeen
        self.penSize = penSize
        self.lastActiveModelId = lastActiveModelId
    }
}

// MARK: - Classification History (D-006)
struct ClassificationResult: Identifiable, Codable {
    let id: UUID
    let emoji: String
    let confidence: Double
    let timestamp: Date
    let modelId: UUID
    
    init(
        id: UUID = UUID(),
        emoji: String,
        confidence: Double,
        timestamp: Date = Date(),
        modelId: UUID
    ) {
        self.id = id
        self.emoji = emoji
        self.confidence = confidence
        self.timestamp = timestamp
        self.modelId = modelId
    }
}

// MARK: - Playground Items (D-007)
struct PlaygroundItem: Identifiable, Codable, Equatable {
    let id: UUID
    let emoji: String
    let position: PointData
    let size: SizeData
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        emoji: String,
        position: CGPoint,
        size: CGSize,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.emoji = emoji
        self.position = PointData(x: Double(position.x), y: Double(position.y), pressure: 0, azimuth: 0, altitude: 0)
        self.size = SizeData(width: Double(size.width), height: Double(size.height))
        self.timestamp = timestamp
    }
}

// MARK: - Size Data
struct SizeData: Codable, Equatable {
    let width: Double
    let height: Double
    
    func toCGSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
}

// MARK: - Data Validation
struct DataValidator {
    static func validateTrainingSample(_ sample: TrainingSample) -> Bool {
        // Check if emoji is valid
        guard !sample.emoji.isEmpty else { return false }
        
        // Check if strokes are valid
        guard !sample.strokes.isEmpty else { return false }
        
        // Check if canvas size is valid
        guard sample.canvasSize.width > 0 && sample.canvasSize.height > 0 else { return false }
        
        return true
    }
    
    static func validateModelInfo(_ model: ModelInfo) -> Bool {
        // Check if name is valid
        guard !model.name.isEmpty else { return false }
        
        return true
    }
    
    static func validateLabelInfo(_ label: LabelInfo) -> Bool {
        // Check if emoji is valid
        guard !label.emoji.isEmpty else { return false }
        
        // Check if sample count is valid
        guard label.sampleCount >= 0 else { return false }
        
        return true
    }
}

