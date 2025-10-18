//
//  EmojiPicker.swift
//  DrawML
//
//  Created by Whyyy on 16/10/2025.
//

import SwiftUI

struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    @State private var searchText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onEmojiSelected: ((String) -> Void)?
    let onError: ((String) -> Void)?
    
    // Popular emojis for drawing recognition
    private let popularEmojis = [
        "❤️", "⭐", "🌟", "🎯", "🎨", "🎭", "🎪", "🎈", "🎉", "🎊",
        "🏠", "🏡", "🏢", "🏣", "🏤", "🏥", "🏦", "🏧", "🏨", "🏩",
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
        "🌹", "🌺", "🌻", "🌷", "🌵", "🌲", "🌳", "🌴", "🌱", "🌿",
        "🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑",
        "🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐",
        "⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱", "🪀", "🏓",
        "🎸", "🎹", "🎺", "🎷", "🥁", "🎤", "🎧", "📻", "🎵", "🎶"
    ]
    
    // All emoji categories
    private let emojiCategories = [
        "Popular": ["❤️", "⭐", "🌟", "🎯", "🎨", "🎭", "🎪", "🎈", "🎉", "🎊"],
        "Animals": ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🐣"],
        "Nature": ["🌹", "🌺", "🌻", "🌷", "🌵", "🌲", "🌳", "🌴", "🌱", "🌿", "🍀", "🌾", "🌰", "🌰", "🌰", "🌰", "🌰", "🌰", "🌰", "🌰"],
        "Food": ["🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒"],
        "Vehicles": ["🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🛻", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "🛹", "🛼"],
        "Sports": ["⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱", "🪀", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "🪃", "🥅", "⛳", "🪁", "🏹"],
        "Music": ["🎸", "🎹", "🎺", "🎷", "🥁", "🎤", "🎧", "📻", "🎵", "🎶", "🎼", "🎹", "🎸", "🎺", "🎷", "🥁", "🎤", "🎧", "📻", "🎵"],
        "Objects": ["📱", "💻", "🖥️", "⌨️", "🖱️", "🖨️", "📷", "📹", "🎥", "📺", "📻", "☎️", "📞", "📠", "💽", "💾", "💿", "📀", "🧮", "🎞️"]
    ]
    
    init(
        selectedEmoji: Binding<String>,
        onEmojiSelected: ((String) -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self._selectedEmoji = selectedEmoji
        self.onEmojiSelected = onEmojiSelected
        self.onError = onError
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Choose an Emoji")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !selectedEmoji.isEmpty {
                    Text("Selected: \(selectedEmoji)")
                        .font(.title2)
                        .foregroundColor(.blue)
                } else {
                    Text("Please pick an emoji first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search emojis...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Emoji Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                    ForEach(filteredEmojis, id: \.self) { emoji in
                        EmojiButton(
                            emoji: emoji,
                            isSelected: selectedEmoji == emoji,
                            onTap: {
                                selectEmoji(emoji)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
        }
        .alert("Emoji Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var filteredEmojis: [String] {
        if searchText.isEmpty {
            return popularEmojis
        } else {
            return popularEmojis.filter { emoji in
                // Simple search - in a real app you might want more sophisticated search
                emoji.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func selectEmoji(_ emoji: String) {
        selectedEmoji = emoji
        onEmojiSelected?(emoji)
    }
}

struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Emoji Picker Sheet
struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    
    let onEmojiSelected: ((String) -> Void)?
    
    var body: some View {
        NavigationView {
            EmojiPicker(
                selectedEmoji: $selectedEmoji,
                onEmojiSelected: { emoji in
                    onEmojiSelected?(emoji)
                    dismiss()
                }
            )
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Emoji Utilities
struct EmojiUtils {
    static func validateEmoji(_ emoji: String) -> Bool {
        // Check if the string is a valid emoji
        return emoji.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji
        }
    }
    
    static func getEmojiName(_ emoji: String) -> String {
        // Return a human-readable name for the emoji
        // This is a simplified version - in practice you'd use a more comprehensive mapping
        switch emoji {
        case "❤️": return "Red Heart"
        case "⭐": return "Star"
        case "🌟": return "Star with Rays"
        case "🎯": return "Direct Hit"
        case "🎨": return "Artist Palette"
        case "🐶": return "Dog Face"
        case "🐱": return "Cat Face"
        case "🏠": return "House"
        case "🌹": return "Rose"
        case "🍎": return "Red Apple"
        default: return "Emoji"
        }
    }
}

#Preview {
    VStack {
        Text("Emoji Picker Preview")
            .font(.headline)
            .padding()
        
        EmojiPicker(
            selectedEmoji: .constant("❤️"),
            onEmojiSelected: { emoji in
                print("Selected emoji: \(emoji)")
            }
        )
        .frame(height: 400)
        .border(Color.gray, width: 1)
    }
}
