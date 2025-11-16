//
//  ModelsView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI

struct ModelsView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingCreateModel = false
    @State private var showingRenameModel: ModelInfo? = nil
    @State private var showingDeleteConfirmation: ModelInfo? = nil
    @State private var newModelName = ""
    @State private var renameModelName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Model Manager")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create, rename, and manage your AI models")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Models List
                if dataManager.models.isEmpty {
                    EmptyModelsView()
                } else {
                    ScrollView {
                        Group {
                            if DeviceUtils.isPad {
                                // iPad: Grid layout
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(dataManager.models) { model in
                                        ModelRowView(
                                            model: model,
                                            onRename: { showingRenameModel = model },
                                            onDelete: { showingDeleteConfirmation = model },
                                            onSetActive: { dataManager.setActiveModel(model) }
                                        )
                                    }
                                }
                                .padding(.horizontal, DeviceUtils.optimalPadding)
                                .padding(.top, 20)
                            } else {
                                // iPhone: Vertical list
                                LazyVStack(spacing: 12) {
                                    ForEach(dataManager.models) { model in
                                        ModelRowView(
                                            model: model,
                                            onRename: { showingRenameModel = model },
                                            onDelete: { showingDeleteConfirmation = model },
                                            onSetActive: { dataManager.setActiveModel(model) }
                                        )
                                    }
                                }
                                .padding(.horizontal, DeviceUtils.optimalPadding)
                                .padding(.top, 20)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Create New Model Button
                Button(action: { showingCreateModel = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Create New Model")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateModel) {
            CreateModelSheet(
                modelName: $newModelName,
                isPresented: $showingCreateModel
            )
        }
        .sheet(item: $showingRenameModel) { model in
            RenameModelSheet(
                model: model,
                newName: $renameModelName,
                isPresented: $showingRenameModel
            )
        }
        .alert("Delete Model", isPresented: Binding<Bool>(
            get: { showingDeleteConfirmation != nil },
            set: { if !$0 { showingDeleteConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = nil
            }
            Button("Delete", role: .destructive) {
                if let model = showingDeleteConfirmation {
                    dataManager.removeModel(model)
                    showingDeleteConfirmation = nil
                }
            }
        } message: {
            if let model = showingDeleteConfirmation {
                Text("Are you sure you want to delete '\(model.name)'? This will also delete all training samples and labels for this model.")
            }
        }
    }
}

struct EmptyModelsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Models Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first model to start training")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

struct ModelRowView: View {
    let model: ModelInfo
    let onRename: () -> Void
    let onDelete: () -> Void
    let onSetActive: () -> Void
    
    @StateObject private var dataManager = DataManager.shared
    
    private var sampleCount: Int {
        dataManager.getTrainingSamples(for: model.id).count
    }
    
    private var labelCount: Int {
        dataManager.getLabels(for: model.id).count
    }
    
    private var hasTrainedModel: Bool {
        dataManager.hasTrainedModel(for: model.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if model.isActive {
                            Text("ACTIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("Created: \(model.createdDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastTrained = model.lastTrained {
                        Text("Last trained: \(lastTrained, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 8) {
                    if !model.isActive {
                        Button("Set Active") {
                            onSetActive()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    
                    Button("Rename") {
                        onRename()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
                    
                    Button("Delete") {
                        onDelete()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(6)
                }
            }
            
            // Stats Row
            HStack(spacing: 20) {
                StatItem(
                    icon: "pencil.circle.fill",
                    label: "Samples",
                    value: "\(sampleCount)",
                    color: .green
                )
                
                StatItem(
                    icon: "tag.fill",
                    label: "Labels",
                    value: "\(labelCount)",
                    color: .purple
                )
                
                StatItem(
                    icon: "brain.head.profile",
                    label: "Trained",
                    value: hasTrainedModel ? "Yes" : "No",
                    color: hasTrainedModel ? .blue : .gray
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CreateModelSheet: View {
    @Binding var modelName: String
    @Binding var isPresented: Bool
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Create New Model")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Give your new AI model a name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Name")
                        .font(.headline)
                    
                    TextField("Enter model name", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        modelName = ""
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Button("Create") {
                        createModel()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(modelName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(8)
                    .disabled(modelName.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private func createModel() {
        let newModel = ModelInfo(
            name: modelName.trimmingCharacters(in: .whitespacesAndNewlines),
            isActive: dataManager.models.isEmpty
        )
        
        if dataManager.addModel(newModel) {
            modelName = ""
            isPresented = false
        }
    }
}

struct RenameModelSheet: View {
    let model: ModelInfo
    @Binding var newName: String
    @Binding var isPresented: ModelInfo?
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Rename Model")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Change the name of '\(model.name)'")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Name")
                        .font(.headline)
                    
                    TextField("Enter new name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        newName = ""
                        isPresented = nil
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Button("Rename") {
                        renameModel()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(newName.isEmpty ? Color.gray : Color.orange)
                    .cornerRadius(8)
                    .disabled(newName.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                newName = model.name
            }
        }
    }
    
    private func renameModel() {
        let updatedModel = ModelInfo(
            id: model.id,
            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
            createdDate: model.createdDate,
            lastTrained: model.lastTrained,
            isActive: model.isActive
        )
        
        if dataManager.updateModel(updatedModel) {
            newName = ""
            isPresented = nil
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ModelsView()
}
