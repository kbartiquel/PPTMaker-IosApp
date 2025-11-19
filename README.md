# PPT Maker iOS App

AI-powered PowerPoint presentation generator for iOS. Create professional presentations in seconds with a two-step workflow that gives you full creative control.

## Features

- 🎯 **Two-Step Workflow**: Generate AI outline → Edit content → Create presentation
- 🎨 **15 Professional Templates**: From corporate to creative, minimal to vibrant
- ✏️ **Editable Outlines**: Full control over titles, bullets, and slide structure
- 📱 **Presentation History**: Browse and manage all your saved presentations
- 👁️ **In-App Preview**: QuickLook integration for viewing .pptx files
- 🎮 **Haptic Feedback**: Tactile response throughout the app
- 📚 **Onboarding Tutorial**: 4-page introduction for first-time users
- 💾 **File Management**: Save, share, and delete presentations
- 🚀 **Fast & Responsive**: SwiftUI-based modern interface

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Backend server running (localhost or production)

## Installation & Setup

### 1. Clone the Repository

```bash
git clone git@github.com:kbartiquel/PPTMaker-IosApp.git
cd PPTMaker-IosApp
```

### 2. Open in Xcode

```bash
open PPTMaker.xcodeproj
```

### 3. Configure Backend URL

Update `APIService.swift` with your backend URL:

```swift
class APIService {
    // Development
    static let baseURL = "http://localhost:8000"

    // Production (when deployed to Render)
    // static let baseURL = "https://your-app.onrender.com"
}
```

### 4. Configure Info.plist Settings

In Xcode project settings, add these keys:

- **UIFileSharingEnabled**: YES (Enables file sharing via Files app)
- **LSSupportsOpeningDocumentsInPlace**: YES (Allows in-place document editing)
- **NSAppTransportSecurity > NSAllowsLocalNetworking**: YES (For localhost backend)

### 5. Build & Run

Press `⌘R` or click the Run button in Xcode.

## Project Structure

```
PPTMaker/
└── PPTMaker/
    ├── Models/
    │   ├── Template.swift           # 15 template definitions
    │   └── SlideModels.swift        # API request/response models
    │
    ├── Services/
    │   ├── APIService.swift         # Backend communication
    │   ├── FileService.swift        # File management
    │   └── HapticManager.swift      # Haptic feedback
    │
    ├── ViewModels/
    │   └── PresentationViewModel.swift  # Main business logic (MVVM)
    │
    ├── Views/
    │   ├── ContentView.swift            # Main interface
    │   ├── OutlineEditorView.swift      # Edit slides & structure
    │   ├── TemplateSelectionView.swift  # Choose design template
    │   ├── PresentationHistoryView.swift # Browse saved files
    │   └── OnboardingView.swift         # First-launch tutorial
    │
    └── PPTMakerApp.swift           # App entry point
```

## User Workflow

### Step 1: Generate Outline
1. Enter presentation topic (e.g., "Climate Change Solutions")
2. Choose number of slides (5-15)
3. Tap "Generate Outline"
4. AI creates structured outline with titles and bullet points

### Step 2: Edit Outline
1. Review generated outline
2. Tap "Edit Outline" to customize
3. Edit slide titles and bullet points
4. Add, remove, or reorder slides
5. Save changes

### Step 3: Choose Template
1. Browse 15 professional templates
2. Preview color schemes
3. Select template that matches your topic

### Step 4: Generate Presentation
1. Tap "Generate Presentation"
2. Backend creates .pptx file
3. Choose: Preview, Share, or Create Another

### Step 5: Manage History
1. Tap history button (clock icon)
2. View all saved presentations
3. Tap to preview in QuickLook
4. Swipe for delete or share actions

## Architecture

### MVVM Pattern
- **Models**: Data structures for templates, slides, API requests
- **Views**: SwiftUI interface components
- **ViewModels**: Business logic and state management (@Published properties)

### Services Layer
- **APIService**: Async/await network calls to backend
- **FileService**: Local file storage in Documents directory
- **HapticManager**: Centralized haptic feedback

### Key Technologies
- **SwiftUI**: Declarative UI framework
- **Combine**: @Published properties for reactive state
- **URLSession**: HTTP networking
- **Codable**: JSON serialization/deserialization
- **QuickLook**: .pptx file preview
- **UIKit Haptics**: Tactile feedback

## Available Templates

All 15 templates match backend designs exactly:

| ID | Name | Style | Use Case |
|----|------|-------|----------|
| corporate | Corporate Professional | Navy blue business | Corporate presentations |
| creative | Creative Bold | Purple & pink vibrant | Creative pitches |
| academic | Academic Classic | Blue & gold traditional | Academic lectures |
| minimal | Minimal Modern | Black & green sleek | Modern aesthetics |
| warm | Warm & Friendly | Orange & green inviting | Community talks |
| tech | Tech Startup | Indigo gradient | Tech startups |
| nature | Nature Eco | Green earth-tones | Environmental topics |
| luxury | Luxury Premium | Dark & gold elegant | High-end presentations |
| vibrant | Vibrant Energy | Multi-color bright | Energetic content |
| monochrome | Monochrome Elegant | Black & white | Sophisticated themes |
| sunset | Sunset Glow | Orange & pink warm | Warm presentations |
| ocean | Ocean Blue | Blue & teal calming | Calming topics |
| dark | Professional Dark | Dark mode business | Modern dark themes |
| pastel | Pastel Soft | Soft pastels | Gentle presentations |
| retro | Retro Vintage | 80s/90s inspired | Retro themes |

## API Integration

### Generate Outline (Step 1)
```swift
func generateOutline(topic: String, numSlides: Int) async throws -> PresentationOutline {
    let url = URL(string: "\(baseURL)/generate-outline")!
    let requestBody = OutlineRequest(topic: topic, numSlides: numSlides)
    // POST request, returns PresentationOutline
}
```

### Generate Presentation (Step 2)
```swift
func generatePresentation(presentationTitle: String, slides: [SlideData], template: String) async throws -> Data {
    let url = URL(string: "\(baseURL)/generate-presentation")!
    let requestBody = PresentationRequest(...)
    // POST request, returns .pptx file data
}
```

## File Management

Presentations are saved to:
```
Documents/
├── Climate_Change_Solutions_2024-11-19.pptx
├── Marketing_Strategy_2024-11-18.pptx
└── ...
```

Access via:
- In-app History view
- iOS Files app (if UIFileSharingEnabled is YES)
- Share sheet to other apps

## Haptic Feedback

Tactile feedback enhances UX:
- **Light tap**: Navigation, selections, minor actions
- **Medium tap**: Primary actions (generate outline, create presentation)
- **Selection**: Template picker changes
- **Success**: Presentation created successfully
- **Error**: Failed operations

## Onboarding

First-launch tutorial (non-skippable):
1. **AI-Powered Presentations** - Overview with example topics
2. **Edit & Customize** - Outline editing capabilities
3. **15 Beautiful Templates** - Template selection
4. **Download & Share** - File management

Shown once, controlled by UserDefaults key: `hasSeenOnboarding`

## Testing

### Manual Testing Checklist
- [ ] First launch shows onboarding (4 pages)
- [ ] Generate outline creates editable slides
- [ ] Edit outline saves changes correctly
- [ ] Template selection updates preview colors
- [ ] Generate presentation creates .pptx file
- [ ] Preview shows slides in QuickLook
- [ ] Share sheet works correctly
- [ ] History displays all saved presentations
- [ ] Delete removes files permanently
- [ ] Haptic feedback triggers on all interactions

### Backend Connection
Ensure backend is running:
```bash
cd backend
source venv/bin/activate
python main.py
# Server on http://localhost:8000
```

Test connection:
```bash
curl http://localhost:8000/health
```

## Troubleshooting

### Network Errors
- **Issue**: Cannot connect to backend
- **Fix**: Verify backend is running on correct port
- **Fix**: Check NSAllowsLocalNetworking is YES in Info.plist

### Build Errors
- **Issue**: "Build input file cannot be found: Info.plist"
- **Fix**: Remove Info.plist file, use Xcode build settings instead

- **Issue**: "Multiple commands produce Info.plist"
- **Fix**: Ensure only Xcode-generated Info.plist exists

### Preview Not Working
- **Issue**: QuickLook shows blank screen
- **Fix**: Verify .pptx file was saved correctly
- **Fix**: Check file permissions in Documents directory

## Deployment

### TestFlight Beta
1. Archive app in Xcode (Product > Archive)
2. Upload to App Store Connect
3. Configure TestFlight settings
4. Invite beta testers

### App Store Submission
1. Update version and build number
2. Create App Store listing
3. Upload screenshots (6.7", 6.5", 5.5")
4. Submit for review
5. Monitor review status

## App Configuration

- **Bundle ID**: com.kimbytes.pptmaker
- **Display Name**: PPT Maker
- **Minimum iOS**: 16.0
- **Supported Devices**: iPhone, iPad
- **Orientation**: Portrait

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

Copyright © 2025 kimbytes. All rights reserved.

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/kbartiquel/PPTMaker-IosApp/issues)
- Email: [your-email]

## Backend Repository

The backend server code is maintained separately:
- Repository: [PPTMaker-Server](https://github.com/kbartiquel/PPTMaker-Server)

## Changelog

### v1.0.0 (Current)
- Initial release
- Two-step AI workflow (outline → edit → generate)
- 15 professional templates
- Presentation history with QuickLook preview
- Haptic feedback throughout
- Non-skippable onboarding tutorial
- File management (save, share, delete)
- MVVM architecture
- SwiftUI interface
