# Flutter Web Setup - Installation Guide

## 📋 Prerequisites

Before running the Flutter application, you need to install Flutter SDK.

### Windows Installation

1. **Download Flutter SDK**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable release
   - Extract to `C:\src\flutter` (or your preferred location)

2. **Add to PATH**
   ```powershell
   # Add Flutter to your PATH environment variable
   $env:Path += ";C:\src\flutter\bin"
   
   # Make it permanent (run as Administrator)
   [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "Machine")
   ```

3. **Verify Installation**
   ```bash
   flutter doctor
   ```

4. **Install Chrome** (if not already installed)
   - Flutter web requires Chrome for development
   - Download from: https://www.google.com/chrome/

---

## 🚀 Running the Application

Once Flutter SDK is installed:

### 1. Navigate to Frontend Directory
```bash
cd C:\Users\Os\.gemini\antigravity\scratch\InmuFacil_Project\frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Enable Web Support
```bash
flutter config --enable-web
```

### 4. Run in Chrome
```bash
flutter run -d chrome
```

The application will open in Chrome at `http://localhost:XXXXX`

---

## 🎨 What You'll See

**Home Screen (Idle Design):**
- Split-screen hero layout
- Left: Search form with filters (property type, location, price range)
- Right: Interactive map with property pins
- Responsive design (works on desktop and mobile)
- Multi-language support (9 variants)

---

## 🔧 Development Commands

### Hot Reload
Press `r` in the terminal to hot reload changes

### Hot Restart
Press `R` in the terminal to hot restart the app

### Quit
Press `q` to quit the development server

### Build for Production
```bash
flutter build web
```
Output will be in `build/web/`

---

## 🌍 Language Support

The app supports 9 regional variants:
- 🇪🇸 Español (España) - Default
- 🇪🇸 Català
- 🇪🇸 Euskara
- 🇪🇸 Galego
- 🇬🇧 English (UK)
- 🇺🇸 English (US)
- 🇨🇦 English (Canada)
- 🇫🇷 Français (France)
- 🇨🇦 Français (Canada)

---

## 📱 Platforms Supported

- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Android** (requires Android Studio)
- ✅ **iOS** (requires Xcode on macOS)
- ✅ **Windows** (desktop)
- ✅ **macOS** (desktop)
- ✅ **Linux** (desktop)

---

## 🐛 Troubleshooting

### "flutter: command not found"
- Flutter SDK not in PATH
- Restart terminal after adding to PATH
- Verify with `flutter doctor`

### "No devices found"
- Chrome not installed
- Run `flutter devices` to see available devices
- Install Chrome or enable web support

### "pub get failed"
- Check internet connection
- Delete `pubspec.lock` and try again
- Run `flutter clean` then `flutter pub get`

### "EasyLocalization error"
- Ensure `assets/translations/` folder exists
- Verify `pubspec.yaml` includes assets
- Check translation files are valid JSON

---

## 📚 Next Steps

1. Install Flutter SDK (see above)
2. Run `flutter pub get`
3. Run `flutter run -d chrome`
4. View application in browser
5. Start developing! 🎉

---

## 🔗 Useful Links

- Flutter Docs: https://docs.flutter.dev
- Flutter Web: https://docs.flutter.dev/platform-integration/web
- EasyLocalization: https://pub.dev/packages/easy_localization
- GoRouter: https://pub.dev/packages/go_router
- Riverpod: https://riverpod.dev

---

**Ready to see InmuFácil in action!** 🚀
