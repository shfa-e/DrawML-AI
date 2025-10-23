//
//  PlaygroundView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI
import PencilKit
import Combine

struct PlaygroundView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var trainingManager = ModelTrainingManager.shared
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var playgroundItems: [PlaygroundItem] = []
    @State private var isRecognizing = false
    @State private var lastRecognitionTime = Date()
    @State private var lastStrokeTime: Date? = nil
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingShakeMessage = false
    @State private var shakeOffset: CGFloat = 0
    @State private var recognitionTimer: Timer?
    @State private var isIdle = false
    
    // Computed properties
    private var activeModel: ModelInfo? {
        dataManager.getActiveModel()
    }
    
    private var hasTrainedModel: Bool {
        guard let model = activeModel else { return false }
        return dataManager.hasTrainedModel(for: model.id)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    // Main Content
                    VStack(spacing: 0) {
                        // Header
                        PlaygroundHeader(
                            activeModel: activeModel,
                            hasTrainedModel: hasTrainedModel,
                            onClearCanvas: clearCanvas
                        )
                        
                        // Canvas Area
                        ZStack {
                            // Drawing Canvas
                            PlaygroundCanvasView(
                                canvasView: $canvasView,
                                toolPicker: $toolPicker,
                                onDrawingChanged: handleDrawingChanged,
                                onError: handleError
                            )
                            
                            // Emoji Overlays
                            ForEach(playgroundItems) { item in
                                EmojiOverlayView(item: item)
                            }
                            
                            // Shake Animation Overlay
                            if showingShakeMessage {
                                ShakeMessageOverlay(
                                    message: "Couldn't classify that drawing.",
                                    offset: shakeOffset
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding()
                        
                        // Bottom Controls
                        PlaygroundControls(
                            isRecognizing: isRecognizing,
                            onClearCanvas: clearCanvas,
                            onToggleRecognition: toggleRecognition
                        )
                    }
                    
                    // iPad Side Panel
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                PlaygroundSidePanel(
                                    recentItems: Array(playgroundItems.suffix(5))
                                )
                                .frame(width: 200)
                                .padding(.trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            setupPlayground()
        }
        .onDisappear {
            cleanup()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Setup and Cleanup
    
    private func setupPlayground() {
        // Load playground items
        playgroundItems = dataManager.playgroundItems
        
        // Setup tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        
        // Start recognition timer
        startRecognitionTimer()
    }
    
    private func cleanup() {
        recognitionTimer?.invalidate()
        recognitionTimer = nil
    }
    
    // MARK: - Recognition Logic
    
    private func startRecognitionTimer() {
        recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkForRecognition()
        }
    }
    
    private func checkForRecognition() {
        guard hasTrainedModel,
              let model = activeModel,
              !isRecognizing,
              !canvasView.drawing.strokes.isEmpty else {
            return
        }
        
        // Check if drawing has changed since last recognition
        let timeSinceLastRecognition = Date().timeIntervalSince(lastRecognitionTime)
        guard timeSinceLastRecognition > 1.0 else { return }
        
        // Check idle time since the last stroke we observed
        if let lastStrokeTime {
            let timeSinceLastStroke = Date().timeIntervalSince(lastStrokeTime)
            guard timeSinceLastStroke > 0.5 else { return }
        } else {
            // If we don't know a last stroke time yet, defer recognition until we do
            return
        }
        
        performRecognition(for: model)
    }
    
    private func performRecognition(for model: ModelInfo) {
        isRecognizing = true
        
        Task {
            let result = await trainingManager.predictDrawing(canvasView.drawing, modelId: model.id)
            
            await MainActor.run {
                isRecognizing = false
                lastRecognitionTime = Date()
                
                if let (emoji, confidence) = result {
                    if confidence > 0.7 { // High confidence threshold
                        replaceDrawingWithEmoji(emoji: emoji, confidence: confidence)
                    } else {
                        showShakeMessage()
                    }
                } else {
                    showShakeMessage()
                }
            }
        }
    }
    
    // MARK: - Drawing Handling
    
    private func handleDrawingChanged() {
        // Reset idle state
        isIdle = false
        
        lastStrokeTime = Date()
        
        // Clear any existing shake message
        if showingShakeMessage {
            showingShakeMessage = false
        }
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    // MARK: - Emoji Replacement
    
    private func replaceDrawingWithEmoji(emoji: String, confidence: Double) {
        // Calculate drawing bounds
        let drawingBounds = canvasView.drawing.bounds
        guard !drawingBounds.isEmpty else { return }
        
        // Create playground item
        let item = PlaygroundItem(
            emoji: emoji,
            position: drawingBounds.origin,
            size: drawingBounds.size
        )
        
        // Add to playground items
        playgroundItems.append(item)
        dataManager.addPlaygroundItem(item)
        
        // Add to classification history
        if let model = activeModel {
            let result = ClassificationResult(
                emoji: emoji,
                confidence: confidence,
                modelId: model.id
            )
            dataManager.addClassificationResult(result)
        }
        
        // Clear the drawing
        canvasView.drawing = PKDrawing()
    }
    
    // MARK: - Shake Animation
    
    private func showShakeMessage() {
        showingShakeMessage = true
        
        // Animate shake
        withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
            shakeOffset = 10
        }
        
        // Hide message after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingShakeMessage = false
            shakeOffset = 0
        }
    }
    
    // MARK: - Controls
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        playgroundItems.removeAll()
        dataManager.clearPlaygroundItems()
    }
    
    private func toggleRecognition() {
        if recognitionTimer != nil {
            recognitionTimer?.invalidate()
            recognitionTimer = nil
        } else {
            startRecognitionTimer()
        }
    }
}

// MARK: - Playground Header

struct PlaygroundHeader: View {
    let activeModel: ModelInfo?
    let hasTrainedModel: Bool
    let onClearCanvas: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Playground")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(activeModel?.name ?? "No Model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(hasTrainedModel ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(hasTrainedModel ? "Ready" : "Needs Training")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !hasTrainedModel {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Train your model first to see live recognition")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Playground Canvas

struct PlaygroundCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    let onDrawingChanged: () -> Void
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = UIColor.clear
        canvasView.isOpaque = false
        
        // Configure tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: PlaygroundCanvasView
        
        init(_ parent: PlaygroundCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChanged()
            // No additional code needed here
        }
    }
}

// MARK: - Emoji Overlay

struct EmojiOverlayView: View {
    let item: PlaygroundItem
    @State private var isVisible = false
    
    var body: some View {
        Text(item.emoji)
            .font(.system(size: min(item.size.width, item.size.height) * 0.8))
            .position(x: item.position.x + item.size.width / 2, 
                     y: item.position.y + item.size.height / 2)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Shake Message Overlay

struct ShakeMessageOverlay: View {
    let message: String
    let offset: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                    .offset(x: offset)
                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Playground Controls

struct PlaygroundControls: View {
    let isRecognizing: Bool
    let onClearCanvas: () -> Void
    let onToggleRecognition: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onClearCanvas) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red)
                .cornerRadius(8)
            }
            
            Spacer()
            
            if isRecognizing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Recognizing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - iPad Side Panel

struct PlaygroundSidePanel: View {
    let recentItems: [PlaygroundItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Emojis")
                .font(.headline)
                .foregroundColor(.primary)
            
            if recentItems.isEmpty {
                Text("No emojis yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(recentItems) { item in
                        Text(item.emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    PlaygroundView()
}
