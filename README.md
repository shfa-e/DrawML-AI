# DrawML

**DrawML** is an educational iOS and iPadOS app that teaches users about machine learning by letting them train their own drawing recognition models. Draw shapes, label them with emojis, train your model, and watch it recognize your drawings in real-time!

## 🎯 Overview

DrawML makes AI accessible and fun. Users draw shapes on a canvas, associate them with emoji labels, and train a Core ML model to recognize those patterns. The app uses Apple's `UpdatableDrawingClassifier` to create personalized drawing recognition models that work entirely on-device.

### Key Features

- **🎨 Interactive Drawing Canvas** - Draw with your finger or Apple Pencil
- **😊 Emoji Labeling** - Associate drawings with emojis to teach your model
- **🧠 On-Device Training** - Train Core ML models directly on your device
- **🎮 Live Playground** - Test your model with instant recognition
- **📱 Universal Support** - Works on both iPhone and iPad with adaptive layouts
- **💾 Multiple Models** - Create, manage, and switch between different models
- **🌙 Dark Mode** - Full support for light and dark appearances
- **📚 Built-in Help** - Onboarding tips and usage guide

## ✨ Features

### Training Mode
- Draw shapes on an interactive canvas
- Pick emoji labels for your drawings
- Add multiple training samples per emoji
- Train your model with a single tap
- View sample counts for each label

### Playground Mode
- Real-time drawing recognition
- Instant emoji replacement when shapes are recognized
- Draw multiple shapes without clearing
- Visual feedback with shake animation for unrecognized drawings
- Draw over existing emojis for continuous recognition

### Model Management
- Create multiple models for different use cases
- Rename and delete models
- Switch between active models
- View training history and statistics

### Data & Privacy
- **100% Offline** - All processing happens on your device
- **No Permissions Required** - No camera, microphone, or location access needed
- **Secure Storage** - All data stored locally using UserDefaults and Core Data
- **Privacy First** - Your drawings never leave your device

## 🛠️ Requirements

- **iOS 15.0+** or **iPadOS 15.0+**
- **Xcode 14.0+** (for development)
- **Swift 5.7+**
- **Core ML** framework
- **PencilKit** framework

## 📦 Installation

### For Users
1. Clone this repository
2. Open `DrawML.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (⌘R)

### For Developers
```bash
# Clone the repository
git clone https://github.com/yourusername/DrawML.git
cd DrawML

# Open in Xcode
open DrawML.xcodeproj
```

## 🚀 Getting Started

### First Launch
When you first open DrawML, you'll see an onboarding guide that walks you through the process:

1. **Draw** - Create a shape on the canvas
2. **Label** - Pick an emoji that represents your drawing
3. **Train** - Add multiple samples and train your model
4. **Test** - Go to Playground to see your model in action

### Basic Workflow

1. **Navigate to Train** from the home screen
2. **Draw a shape** (e.g., a star, circle, or heart)
3. **Select an emoji** from the emoji picker
4. **Tap "Add Sample"** to save the training example
5. **Repeat** steps 2-4 with variations of the same shape
6. **Tap "Train Model"** to update your model
7. **Go to Playground** to test recognition in real-time

### Tips for Best Results

- **Add 5-10 samples per emoji** for better recognition
- **Draw the same shape in different ways** to improve accuracy
- **Use clear, simple shapes** for best results
- **Train after adding several samples** to see improvements

## 📱 Screens

### Home Screen
- Quick access to all features
- Shows active model name
- Navigation to Train, Playground, Models, and Help

### Train Screen
- Drawing canvas
- Emoji picker
- Add Sample button
- Train Model button
- Sample grid preview
- Clear canvas option

### Playground Screen
- Large drawing canvas
- Live recognition
- Instant emoji replacement
- Multi-shape support
- Visual feedback for unrecognized drawings

### Models Screen
- List of all models
- Create new models
- Rename/delete models
- Set active model

### Labels Screen
- View all trained emojis
- Sample count per label
- Delete labels

### Help Screen
- Onboarding guide
- Usage tips
- Best practices

## 🏗️ Architecture

### Project Structure
```
DrawML/
├── DrawMLApp.swift          # App entry point
├── ContentView.swift         # Root view
├── HomeView.swift            # Main navigation screen
├── TrainView.swift           # Training interface
├── PlaygroundView.swift      # Live recognition playground
├── ModelsView.swift          # Model management
├── LabelsView.swift          # Label viewing
├── HelpView.swift            # Onboarding and help
├── DrawingCanvas.swift       # Reusable drawing component
├── EmojiPicker.swift         # Emoji selection component
├── DataManager.swift         # Data persistence layer
├── DataModels.swift          # Core data structures
├── ModelTrainingManager.swift # Core ML training logic
└── UpdatableDrawingClassifier.mlmodel # Core ML model
```

### Key Components

- **DataManager**: Singleton managing all app data persistence
- **ModelTrainingManager**: Handles Core ML model training and updates
- **DrawingCanvas**: Reusable PencilKit-based drawing component
- **DataModels**: Codable structures for training samples, models, labels, etc.

### Technologies Used

- **SwiftUI** - Modern declarative UI framework
- **Core ML** - On-device machine learning
- **PencilKit** - Drawing and stroke recognition
- **Combine** - Reactive programming for data flow
- **UserDefaults** - Lightweight data persistence

## 🎨 Design Principles

- **Simple & Intuitive** - Easy to understand and use
- **Educational** - Teaches ML concepts through hands-on experience
- **Offline First** - All functionality works without internet
- **Privacy Focused** - No data collection or external services
- **Universal** - Adapts to iPhone and iPad screen sizes

## 📝 Development Status

### Completed Features ✅
- Drawing canvas with PencilKit
- Emoji picker and labeling
- Training sample management
- Core ML model training
- Live playground recognition
- Multiple model support
- Data persistence
- Labels viewing
- Onboarding and help system
- Dark mode support
- Universal layout (iPhone/iPad)

### Future Enhancements 🔮
- Export/import models
- Model sharing
- Advanced training statistics
- Custom drawing tools
- More recognition feedback options

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is available for use under the MIT License. See LICENSE file for details.

## 🙏 Acknowledgments

- Built with Apple's Core ML and PencilKit frameworks
- Uses `UpdatableDrawingClassifier` for on-device model training
- Designed for educational purposes to make ML accessible

## 📧 Contact

For questions, suggestions, or issues, please open an issue on GitHub.

---

**Made with ❤️ using Swift and SwiftUI**

*Draw • Learn • Test*
