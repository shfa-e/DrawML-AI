//
//  HelpView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("How to Use DrawML")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Learn how to train your AI model")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                // Onboarding Steps
                VStack(alignment: .leading, spacing: 24) {
                    Text("Quick Start Guide")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    // Step 1: Draw
                    OnboardingStepView(
                        stepNumber: 1,
                        title: "Draw",
                        description: "Draw a shape on the canvas using your finger or Apple Pencil. This is what you want your model to learn.",
                        icon: "pencil.and.outline",
                        color: .blue
                    )
                    
                    // Step 2: Label
                    OnboardingStepView(
                        stepNumber: 2,
                        title: "Label",
                        description: "Pick an emoji that represents your drawing. This tells the model what the shape means.",
                        icon: "face.smiling",
                        color: .yellow
                    )
                    
                    // Step 3: Train
                    OnboardingStepView(
                        stepNumber: 3,
                        title: "Train",
                        description: "Add multiple samples for each emoji, then press 'Train Model' to teach your model. More samples = better recognition!",
                        icon: "brain.head.profile",
                        color: .green
                    )
                    
                    // Step 4: Test
                    OnboardingStepView(
                        stepNumber: 4,
                        title: "Test",
                        description: "Go to Playground and draw your shapes. Watch them instantly turn into emojis when recognized!",
                        icon: "gamecontroller.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Tips Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tips")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TipRowView(
                            icon: "lightbulb.fill",
                            text: "Add at least 5-10 samples per emoji for best results"
                        )
                        
                        TipRowView(
                            icon: "arrow.triangle.2.circlepath",
                            text: "Draw the same shape in different ways to improve recognition"
                        )
                        
                        TipRowView(
                            icon: "square.stack.3d.up.fill",
                            text: "You can create multiple models for different sets of shapes"
                        )
                        
                        TipRowView(
                            icon: "sparkles",
                            text: "In Playground, you can draw multiple shapes without clearing"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                // Footer
                VStack(spacing: 8) {
                    Text("Happy Drawing! 🎨")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OnboardingStepView: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step Number Badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("\(stepNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TipRowView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.body)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        HelpView()
    }
}

