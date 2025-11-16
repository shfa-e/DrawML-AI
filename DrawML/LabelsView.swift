//
//  LabelsView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI

struct LabelsView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingDeleteAlert = false
    @State private var labelToDelete: LabelInfo?
    @State private var showingRenameAlert = false
    @State private var labelToRename: LabelInfo?
    @State private var newLabelName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Computed properties
    private var activeModel: ModelInfo? {
        dataManager.getActiveModel()
    }
    
    private var labels: [LabelInfo] {
        guard let model = activeModel else { return [] }
        return dataManager.getLabels(for: model.id).sorted { $0.emoji < $1.emoji }
    }
    
    private var totalSamples: Int {
        labels.reduce(0) { $0 + $1.sampleCount }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Training Labels")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let model = activeModel {
                        Text("Model: \(model.name)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(labels.count) labels • \(totalSamples) total samples")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Labels List
                if labels.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "face.smiling")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Labels Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Start training your model by adding samples with emojis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        Group {
                            if DeviceUtils.isPad {
                                // iPad: Grid layout
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(labels) { label in
                                        LabelRowView(
                                            label: label,
                                            onDelete: {
                                                labelToDelete = label
                                                showingDeleteAlert = true
                                            },
                                            onRename: {
                                                labelToRename = label
                                                newLabelName = label.name ?? ""
                                                showingRenameAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding(DeviceUtils.optimalPadding)
                            } else {
                                // iPhone: Vertical list
                                LazyVStack(spacing: 12) {
                                    ForEach(labels) { label in
                                        LabelRowView(
                                            label: label,
                                            onDelete: {
                                                labelToDelete = label
                                                showingDeleteAlert = true
                                            },
                                            onRename: {
                                                labelToRename = label
                                                newLabelName = label.name ?? ""
                                                showingRenameAlert = true
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss view
                    }
                }
            }
        }
        .alert("Delete Label", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLabel()
            }
        } message: {
            if let label = labelToDelete {
                Text("Are you sure you want to delete the '\(label.emoji)' label and all its \(label.sampleCount) samples? This action cannot be undone.")
            }
        }
        .alert("Rename Label", isPresented: $showingRenameAlert) {
            TextField("Label name", text: $newLabelName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                renameLabel()
            }
        } message: {
            if let label = labelToRename {
                Text("Enter a name for the '\(label.emoji)' label")
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func deleteLabel() {
        guard let label = labelToDelete else { return }
        
        // Delete all training samples for this emoji
        guard let model = activeModel else {
            showError("No active model found")
            return
        }
        
        let samplesToDelete = dataManager.getTrainingSamples(for: label.emoji, modelId: model.id)
        
        for sample in samplesToDelete {
            dataManager.removeTrainingSample(sample)
        }
        
        // Clear selection
        labelToDelete = nil
    }
    
    private func renameLabel() {
        guard let label = labelToRename else { return }
        
        // Update the label name
        let updatedLabel = LabelInfo(
            id: label.id,
            emoji: label.emoji,
            name: newLabelName.isEmpty ? nil : newLabelName,
            sampleCount: label.sampleCount,
            modelId: label.modelId
        )
        
        // Update in data manager
        if let index = dataManager.labels.firstIndex(where: { $0.id == label.id }) {
            dataManager.labels[index] = updatedLabel
            // Persisting is handled internally by DataManager; avoid calling private saveLabels()
        }
        
        // Clear selection
        labelToRename = nil
        newLabelName = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Label Row View

struct LabelRowView: View {
    let label: LabelInfo
    let onDelete: () -> Void
    let onRename: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji
            Text(label.emoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            
            // Label Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label.name ?? EmojiUtils.getEmojiName(label.emoji))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(label.sampleCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text("\(label.sampleCount) sample\(label.sampleCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let name = label.name, !name.isEmpty {
                    Text("Custom name: \(name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions Button
            Button(action: {
                showingActions.toggle()
            }) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(action: onRename) {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - Label Statistics View

struct LabelStatisticsView: View {
    let labels: [LabelInfo]
    
    private var averageSamples: Double {
        guard !labels.isEmpty else { return 0 }
        let total = labels.reduce(0) { $0 + $1.sampleCount }
        return Double(total) / Double(labels.count)
    }
    
    private var mostSamples: Int {
        labels.map { $0.sampleCount }.max() ?? 0
    }
    
    private var leastSamples: Int {
        labels.map { $0.sampleCount }.min() ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatisticItem(
                    title: "Average",
                    value: String(format: "%.1f", averageSamples),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatisticItem(
                    title: "Most",
                    value: "\(mostSamples)",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                StatisticItem(
                    title: "Least",
                    value: "\(leastSamples)",
                    icon: "arrow.down.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Statistic Item

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LabelsView()
}
