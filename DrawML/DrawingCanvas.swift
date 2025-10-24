//
//  DrawingCanvas.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI
import PencilKit

struct DrawingCanvas: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Callbacks for parent views
    let onDrawingChanged: (() -> Void)?
    let onError: ((String) -> Void)?
    
    // Configuration
    let isEditable: Bool
    let backgroundColor: Color
    
    init(
        isEditable: Bool = true,
        backgroundColor: Color = .white,
        onDrawingChanged: (() -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.isEditable = isEditable
        self.backgroundColor = backgroundColor
        self.onDrawingChanged = onDrawingChanged
        self.onError = onError
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            // Drawing Canvas
            CanvasViewRepresentable(
                canvasView: $canvasView,
                toolPicker: $toolPicker,
                isEditable: isEditable,
                onDrawingChanged: onDrawingChanged,
                onError: onError
            )
            .background(Color.clear)
        }
        .alert("Drawing Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupCanvas()
        }
    }
    
    private func setupCanvas() {
        // Configure canvas
        canvasView.backgroundColor = UIColor.clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        
        // Configure tool picker
        if isEditable {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
        }
        
        // Set up drawing delegate
        canvasView.delegate = DrawingDelegate(
            onDrawingChanged: onDrawingChanged,
            onError: onError
        )
    }
    
    // Public methods for parent views
    func clearCanvas() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Clear with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            canvasView.drawing = PKDrawing()
        }
        
        onDrawingChanged?()
    }
    
    func getDrawing() -> PKDrawing {
        return canvasView.drawing
    }
    
    func setDrawing(_ drawing: PKDrawing) {
        canvasView.drawing = drawing
    }
    
    func hasDrawing() -> Bool {
        return !canvasView.drawing.strokes.isEmpty
    }
}

// MARK: - Canvas View Representable
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    let isEditable: Bool
    let onDrawingChanged: (() -> Void)?
    let onError: ((String) -> Void)?
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update canvas if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onDrawingChanged: onDrawingChanged,
            onError: onError
        )
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: (() -> Void)?
        let onError: ((String) -> Void)?
        
        init(
            onDrawingChanged: (() -> Void)? = nil,
            onError: ((String) -> Void)? = nil
        ) {
            self.onDrawingChanged = onDrawingChanged
            self.onError = onError
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged?()
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            // Handle tool usage start if needed
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // Handle tool usage end if needed
        }
    }
}

// MARK: - Drawing Delegate
class DrawingDelegate: NSObject, PKCanvasViewDelegate {
    let onDrawingChanged: (() -> Void)?
    let onError: ((String) -> Void)?
    
    init(
        onDrawingChanged: (() -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.onDrawingChanged = onDrawingChanged
        self.onError = onError
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        onDrawingChanged?()
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        // Handle tool usage start if needed
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        // Handle tool usage end if needed
    }
}

// MARK: - Drawing Data Model
struct DrawingData {
    let strokes: [PKStroke]
    let canvasSize: CGSize
    let timestamp: Date
    
    init(from drawing: PKDrawing, canvasSize: CGSize) {
        self.strokes = Array(drawing.strokes)
        self.canvasSize = canvasSize
        self.timestamp = Date()
    }
    
    func toPKDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        for stroke in strokes {
            drawing.strokes.append(stroke)
        }
        return drawing
    }
}

// MARK: - Drawing Utilities
struct DrawingUtils {
    static func validateDrawing(_ drawing: PKDrawing) -> Bool {
        // Check if drawing has valid strokes
        guard !drawing.strokes.isEmpty else { return false }
        
        // Check if strokes have valid points
        for stroke in drawing.strokes {
            if stroke.path.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    static func getDrawingBounds(_ drawing: PKDrawing) -> CGRect {
        guard !drawing.strokes.isEmpty else {
            return CGRect.zero
        }
        
        var bounds = drawing.strokes.first?.renderBounds ?? CGRect.zero
        
        for stroke in drawing.strokes {
            bounds = bounds.union(stroke.renderBounds)
        }
        
        return bounds
    }
    
    static func scaleDrawing(_ drawing: PKDrawing, to targetSize: CGSize) -> PKDrawing {
        let bounds = getDrawingBounds(drawing)
        guard bounds.size.width > 0 && bounds.size.height > 0 else {
            return drawing
        }
        
        let scaleX = targetSize.width / bounds.size.width
        let scaleY = targetSize.height / bounds.size.height
        _ = min(scaleX, scaleY)
        
        var scaledDrawing = PKDrawing()
        
        for stroke in drawing.strokes {
            let scaledStroke = stroke
            // Apply scaling transformation to stroke
            // This is a simplified version - in practice, you'd need to transform each point
            scaledDrawing.strokes.append(scaledStroke)
        }
        
        return scaledDrawing
    }
}

#Preview {
    VStack {
        Text("Drawing Canvas Preview")
            .font(.headline)
            .padding()
        
        DrawingCanvas(
            isEditable: true,
            backgroundColor: .gray.opacity(0.1),
            onDrawingChanged: {
                print("Drawing changed")
            },
            onError: { error in
                print("Drawing error: \(error)")
            }
        )
        .frame(height: 300)
        .border(Color.gray, width: 1)
        
        HStack {
            Button("Clear Canvas") {
                // This would be connected to the canvas in a real implementation
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
}
