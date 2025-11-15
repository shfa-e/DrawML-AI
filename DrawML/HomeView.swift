//
//  HomeView.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showOnboarding = false
    
    private var activeModelName: String {
        dataManager.getActiveModel()?.name ?? "No Model"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                VStack(spacing: 8) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("DrawML")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Draw • Learn • Test")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Active Model Display
                VStack(spacing: 8) {
                    Text("Active Model")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(activeModelName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                // Navigation Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: TrainView()) {
                        NavigationButton(
                            title: "Train",
                            subtitle: "Teach your model",
                            icon: "pencil.circle.fill",
                            color: .green
                        ) {
                            // Navigation handled by NavigationLink
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: PlaygroundView()) {
                        NavigationButton(
                            title: "Playground",
                            subtitle: "Test your model",
                            icon: "gamecontroller.fill",
                            color: .orange
                        ) {
                            // Navigation handled by NavigationLink
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: ModelsView()) {
                        NavigationButton(
                            title: "Models",
                            subtitle: "Manage your models",
                            icon: "folder.fill",
                            color: .purple
                        ) {
                            // Navigation handled by NavigationLink
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: HelpView()) {
                        NavigationButton(
                            title: "Help",
                            subtitle: "Learn how to use DrawML",
                            icon: "questionmark.circle.fill",
                            color: .blue
                        ) {
                            // Navigation handled by NavigationLink
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showOnboarding) {
                NavigationView {
                    HelpView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    // Mark onboarding as seen
                                    var settings = dataManager.appSettings
                                    settings.onboardingSeen = true
                                    dataManager.updateAppSettings(settings)
                                    showOnboarding = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                // Show onboarding on first launch
                if !dataManager.appSettings.onboardingSeen {
                    showOnboarding = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures consistent behavior on iPad
    }
}

struct NavigationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}
