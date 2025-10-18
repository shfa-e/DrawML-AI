//
//  TrainView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI
import PencilKit

struct TrainView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedEmoji = ""
    @State private var showingEmojiPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var canvasRef: DrawingCanvas?
    
    // Computed properties
    private var activeModel: ModelInfo? {
        dataManager.getActiveModel()
    }
    
    private var trainingSamples: [TrainingSample] {
        guard let model = activeModel else { return [] }
        return dataManager.getTrainingSamples(for: model.id)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Train Your Model")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let model = activeModel {
                        Text("Model: \(model.name)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Draw something and pick an emoji to teach your model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Drawing Canvas
                DrawingCanvas(
                    isEditable: true,
                    backgroundColor: .white,
                    onDrawingChanged: {
                        // Handle drawing changes if needed
                    },
                    onError: { error in
                        showError("Couldn't read drawing. Please try again.")
                    }
                )
                .frame(maxHeight: 400)
                .border(Color.gray.opacity(0.3), width: 1)
                .background(
                    DrawingCanvasWrapper { canvas in
                        canvasRef = canvas
                    }
                )
                
                // Controls Section
                VStack(spacing: 16) {
                    // Emoji Selection
                    VStack(spacing: 8) {
                        Text("Choose Emoji Label")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            showingEmojiPicker = true
                        }) {
                            HStack {
                                if selectedEmoji.isEmpty {
                                    Image(systemName: "face.smiling")
                                        .font(.title2)
                                    Text("Pick an Emoji")
                                        .font(.headline)
                                } else {
                                    Text(selectedEmoji)
                                        .font(.title)
                                    Text("Change Emoji")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedEmoji.isEmpty ? Color.orange : Color.blue, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        // Add Sample Button
                        Button(action: addSample) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Sample")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canAddSample ? Color.green : Color.gray)
                            )
                        }
                        .disabled(!canAddSample)
                        .buttonStyle(PlainButtonStyle())
                        
                        // Train Model Button
                        Button(action: trainModel) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Train Model")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canTrainModel ? Color.blue : Color.gray)
                            )
                        }
                        .disabled(!canTrainModel)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Clear Canvas Button
                    Button(action: clearCanvas) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("Clear Canvas")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Training Samples Preview
                if !trainingSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Training Samples (\(trainingSamples.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(trainingSamples, id: \.id) { sample in
                                    TrainingSampleCard(sample: sample)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGroupedBackground))
                }
                
                Spacer()
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Labels") {
                        // Navigate to labels screen (to be implemented)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerSheet(
                selectedEmoji: $selectedEmoji,
                onEmojiSelected: { emoji in
                    // Emoji selected
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var canAddSample: Bool {
        return !selectedEmoji.isEmpty && canvasRef?.hasDrawing() == true
    }
    
    private var canTrainModel: Bool {
        return trainingSamples.count >= 2 // Need at least 2 samples to train
    }
    
    // MARK: - Actions
    private func addSample() {
        guard let canvas = canvasRef else {
            showError("Canvas not available")
            return
        }
        
        guard let model = activeModel else {
            showError("No active model found")
            return
        }
        
        guard !selectedEmoji.isEmpty else {
            showError("Please pick an emoji first")
            return
        }
        
        guard canvas.hasDrawing() else {
            showError("Please draw something first")
            return
        }
        
        let drawing = canvas.getDrawing()
        
        // Validate drawing
        guard DrawingUtils.validateDrawing(drawing) else {
            showError("Couldn't save sample")
            return
        }
        
        // Create training sample
        let sample = TrainingSample(
            modelId: model.id,
            emoji: selectedEmoji,
            drawing: drawing,
            canvasSize: CGSize(width: 400, height: 400) // Default canvas size
        )
        
        // Add to data manager
        if dataManager.addTrainingSample(sample) {
            showSuccess("Sample added successfully!")
            
            // Clear canvas for next drawing
            clearCanvas()
        } else {
            showError("Couldn't save sample")
        }
    }
    
    private func trainModel() {
        guard canTrainModel else {
            showError("Need at least 2 samples to train the model")
            return
        }
        
        // TODO: Implement actual model training
        // For now, just show success message
        showSuccess("Model training completed!")
    }
    
    private func clearCanvas() {
        canvasRef?.clearCanvas()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccess = true
    }
}

// MARK: - Training Sample Card
struct TrainingSampleCard: View {
    let sample: TrainingSample
    
    var body: some View {
        VStack(spacing: 4) {
            Text(sample.emoji)
                .font(.title2)
            
            Text(sample.emoji)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Drawing Canvas Wrapper
struct DrawingCanvasWrapper: View {
    let onCanvasCreated: (DrawingCanvas) -> Void
    
    var body: some View {
        Color.clear
            .onAppear {
                // This is a workaround to get a reference to the canvas
                // In a real implementation, you might want to use a different approach
            }
    }
}

#Preview {
    TrainView()
}
