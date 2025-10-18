# DrawML — Requirements Document

## 1) App Overview
- **O-001.** DrawML is a simple iOS and iPadOS app made with **Swift** and **SwiftUI** in **Xcode**.  
- **O-002.** It helps people understand AI by **drawing shapes** that the app learns to recognize.  
- **O-003.** You draw something (like a star), pick an emoji (like ❤️), and train the model to link the two.  
- **O-004.** Later, when you draw again, the app guesses the shape and instantly shows the emoji in that same spot.  
- **O-005.** Works on both **iPhone and iPad** with layouts that adjust to screen size.  

---

## 2) Main Goals
- **G-001.** Teach users how to train a model using `updateableDrawingClassifier.mlmodel`.  
- **G-002.** Let users make **many** drawing models — each model maps drawings to emojis.  
- **G-003.** Let users **draw on a canvas** to teach their model.  
- **G-004.** Let users **pick an emoji label** for the drawing.  
- **G-005.** Let users press **Train Model** to make the model smarter.  
- **G-006.** Let users press **Classify** or see automatic results to test the model.  
- **G-007.** Let users **view trained labels** (the emojis and their sample counts).  
- **G-008.** Let users **clear their canvas** anytime.  
- **G-009.** Let users **test their model in a Playground**, where drawings are recognized instantly.  
- **G-010.** Make the app work smoothly on **iPhone and iPad**.  
- **G-011.** In Playground, make the user’s drawing **change into an emoji right away** when recognized.  
- **G-012.** If the model can’t recognize a drawing, make the **drawing shake** and show a short message.  
- **G-013.** In Playground, allow **many shapes** to be drawn one after another.  
- **G-014.** Allow users to **draw over emojis** and keep recognizing new shapes.  

---

## 3) User Stories
| ID | Story |
|----|--------|
| **US-001** | As a user, I want to draw on a canvas so that I can teach the app my shape. |
| **US-002** | As a user, I want to pick an emoji label so the app knows what I drew. |
| **US-003** | As a user, I want to save many examples per emoji so the model learns better. |
| **US-004** | As a user, I want to train the model so that it gets smarter. |
| **US-005** | As a user, I want to test the model by having it guess my drawing. |
| **US-006** | As a user, I want to see a list of all emojis my model has learned. |
| **US-007** | As a user, I want to clear my canvas and start fresh. |
| **US-008** | As a user, I want a Playground to test the model quickly. |
| **US-009** | As a user, I want to manage multiple models (create, rename, delete). |
| **US-010** | As a user, I want my data saved on my device and work offline. |
| **US-011** | As a user, I want the app to work on both phone and iPad. |
| **US-012** | As a user, I want my sketch to turn into an emoji as I draw. |
| **US-013** | As a user, I want my sketch to shake with a message when not recognized. |
| **US-014** | As a user, I want to draw many shapes in a row without clearing the canvas. |
| **US-015** | As a user, I want to draw on top of emojis and still have the app recognize new shapes. |

---

## 4) Features
### **F-001. Drawing Canvas**
- Lets the user draw with their finger or Apple Pencil.  
- Used in Train and Playground screens.  
- If drawing fails, show “Couldn’t read drawing. Please try again.”

### **F-002. Emoji Picker**
- Choose an emoji label for the current drawing.  
- Appears below the canvas on the Train screen.  
- If no emoji is picked, show “Please pick an emoji first.”

### **F-003. Add Training Sample**
- Saves the current drawing with its emoji label.  
- Button: “Add Sample.”  
- If save fails, show “Couldn’t save sample.”

### **F-004. Train Model**
- Updates `updateableDrawingClassifier.mlmodel` with new samples.  
- If training fails, show “Training failed. Try with more samples.”

### **F-005. Classify Drawing**
- Sends the current drawing to the model and shows the predicted emoji.  
- Used on Playground and (optionally) Train screens.  
- If it fails, show “Couldn’t classify. Try again.”

### **F-006. Emoji Overlay**
- Shows the emoji in the same position and size as the user’s drawing.  
- Appears after a successful classification.

### **F-007. Labels List**
- Shows all emojis and how many samples belong to each.  
- Appears on the Labels screen.

### **F-008. Clear Canvas**
- Wipes the canvas clean.  
- If undo fails, show “Nothing to undo.”

### **F-009. Model Manager**
- Create, rename, delete, and switch between models.  
- Asks “Are you sure?” before delete.

### **F-010. Save & Load**
- Saves all models, samples, and settings on the device.  
- Works offline.

### **F-011. Onboarding Tips**
- Short 3-step guide: Draw → Label → Train → Test.  
- Shows on first launch and under Help.

### **F-012. Live Playground Recognition**
- Checks the user’s drawing in real time.  
- When recognized, replaces the sketch with its emoji instantly.  
- If live check fails, show “Live check paused. Try again.”

### **F-013. Not Recognized Shake + Message**
- When the model can’t tell what a drawing is, it shakes and shows: “Couldn’t classify that drawing.”

### **F-014. Continuous Multi-Shape Canvas**
- Lets users draw multiple shapes one after another; no auto-clear.  
- Keeps recognizing each finished shape.

### **F-015. Draw Over Emojis**
- Lets users draw new shapes on top of old emojis and still get recognition.  
- If detection is confused, show “Try a simpler outline.”

### **F-016. Universal Layout**
- Adjusts UI for iPhone and iPad automatically.  
- iPad uses split-screen layout with larger canvas and optional side panel.

---

## 5) Screens
### **S-001. Home**
- Buttons: **Train**, **Playground**, **Models**, **Help**.  
- Shows active model name.  
- Entry point of the app.

### **S-002. Train**
- Canvas for drawing.  
- Emoji Picker, Add Sample, Train Model, Clear.  
- Small grid of saved samples.  
- Path: Tap **Train** on Home.

### **S-003. Playground (Live Recognition)**
- Big canvas with live recognition (F-012).  
- As soon as a shape is recognized → replaced by emoji.  
- If not recognized → drawing shakes + message (F-013).  
- Users can draw many shapes without clearing (F-014).  
- Users can draw over emojis (F-015).  
- Optional panel on iPad: shows recently placed emojis.  
- Path: Tap **Playground** on Home.

### **S-004. Labels**
- List of emojis the model has learned and sample counts.  
- Delete or rename labels.  
- Path: From Train or Home.

### **S-005. Models**
- List of models.  
- Actions: Create, Rename, Delete, Set Active.  
- Path: Tap **Models** on Home.

### **S-006. Help**
- Simple guide explaining how training and testing works.  
- Path: Tap **Help** on Home.

---

## 6) Data
| ID | Data Type | Description |
|----|------------|--------------|
| **D-001** | Model List | model ID, name, created date, last trained, isActive flag |
| **D-002** | Labels | emoji, optional name, sample count |
| **D-003** | Training Samples | model ID, emoji label, strokes, canvas size, date |
| **D-004** | Trained Model File | on-device `.mlmodel` for each model |
| **D-005** | App Settings | dark mode, onboarding seen, pen size, etc. |
| **D-006** | Classification History | last few predictions (emoji + confidence) |
| **D-007** | Playground Items | emojis placed on canvas (position + size) |

---

## 7) Extra Details
- **X-001.** Works fully **offline**.  
- **X-002.** Stores everything on-device.  
- **X-003.** Needs no permissions (no camera, no mic, no GPS).  
- **X-004.** Supports **Dark Mode** and **Light Mode**.  
- **X-005.** Supports **portrait** (iPhone) and **portrait + landscape** (iPad).  
- **X-006.** Automatically adjusts for screen sizes (Universal Layout).  
- **X-007.** Battery safe: slows live checks when idle.  
- **X-008.** Friendly UX: quick toast messages instead of popups.  
- **X-009.** Keep user data safe — confirm before deleting models.  

---

## 8) Build Steps
| ID | Step |
|----|------|
| **B-001.** Create new SwiftUI project in Xcode (O-001). | ✅
| **B-002.** Add a Home screen (S-001) with buttons for navigation. | ✅
| **B-003.** Build a reusable **Drawing Canvas** (F-001). | ✅
| **B-004.** Add **Emoji Picker** (F-002) to Train screen (S-002). | ✅
| **B-005.** Add **Add Sample** (F-003) and connect to **D-003**. |✅
| **B-006.** Add **Train Model** button (F-004) to update `updateableDrawingClassifier.mlmodel`. |
| **B-007.** Add **Labels List** (S-004) showing label counts (F-007). |
| **B-008.** Add **Model Manager** (S-005) to switch/create models (F-009). |
| **B-009.** Implement **Save & Load** (F-010) for data D-001–D-005. |
| **B-010.** Add **Playground** (S-003) with **live recognition** (F-012). |
| **B-011.** On recognition: replace sketch with emoji (F-006). |
| **B-012.** On failed recognition: shake + show message (F-013). |
| **B-013.** Keep multiple shapes on canvas (F-014) and allow drawing over emojis (F-015). |
| **B-014.** Scale emoji to drawing size (based on stroke bounds). |
| **B-015.** Add **Clear Canvas** (F-008) button for resets. |
| **B-016.** Add **Onboarding Tips** (F-011) under Help (S-006). |
| **B-017.** Make layout adaptive for iPhone/iPad (F-016). |
| **B-018.** Add local save for Playground emojis (D-007). |
| **B-019.** Test all **User Stories (US-001 → US-015)** manually. |
| **B-020.** Polish visuals and add Dark Mode support (X-004). |
| **B-021.** Final test: draw many shapes, test shake message, test both iPhone and iPad views. |

---

## ✅ Summary
DrawML teaches users about AI by **drawing**, **labeling with emojis**, and **training** their own models — all right on their device.  
It’s simple, fun, and instant: **draw → learn → test → see it come alive**.  
The **Playground** gives users immediate feedback and helps them see what their model understands in a friendly, visual way.