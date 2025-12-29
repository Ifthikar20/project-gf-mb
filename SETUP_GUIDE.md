# Flutter Setup & Running Guide for Beginners

This guide will help you set up Flutter and run your wellness app for the first time.

## Prerequisites Status

✅ **Xcode**: Already installed
❌ **Flutter SDK**: Not installed (we'll install this)

---

## Step 1: Install Flutter SDK

### Option A: Using Homebrew (Easiest)

Open Terminal and run:

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Flutter
brew install --cask flutter
```

### Option B: Manual Installation

1. Download Flutter SDK:
   ```bash
   cd ~/Downloads
   curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.zip
   ```

2. Extract and move to a permanent location:
   ```bash
   unzip flutter_macos_arm64_3.16.0-stable.zip
   sudo mv flutter /usr/local/
   ```

3. Add to PATH (add to `~/.zshrc`):
   ```bash
   echo 'export PATH="$PATH:/usr/local/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

---

## Step 2: Verify Flutter Installation

Run this command to check if everything is set up:

```bash
flutter doctor
```

You should see a checklist. Don't worry if some items have warnings initially.

---

## Step 3: Accept Xcode License

```bash
sudo xcodebuild -license accept
```

---

## Step 4: Install iOS Simulator

Xcode comes with simulators. To see available simulators:

```bash
xcrun simctl list devices
```

To install a specific iOS simulator (if needed):
1. Open Xcode
2. Go to **Xcode** → **Preferences** → **Components**
3. Download an iOS simulator version

---

## Step 5: Navigate to Your Project

```bash
cd /Users/ifthikaraliseyed/Downloads/project-gf-mobile
```

---

## Step 6: Install Project Dependencies

This downloads all the packages your app needs:

```bash
flutter pub get
```

You should see output like:
```
Running "flutter pub get" in project-gf-mobile...
Resolving dependencies...
✓ Success!
```

---

## Step 7: Generate Code (Hive Adapters)

The app uses Hive for local storage. Generate the required code:

```bash
flutter packages pub run build_runner build
```

If you see conflicts, use:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## Step 8: Open iOS Simulator

```bash
open -a Simulator
```

This will launch the iOS Simulator. Wait for it to fully boot up.

---

## Step 9: Run Your App!

Now for the exciting part - run your wellness app:

```bash
flutter run
```

### What to Expect:

1. **First time**: Flutter will build the app (takes 2-5 minutes)
2. You'll see build progress in the terminal
3. The app will automatically install and launch on the simulator
4. You'll see output like:
   ```
   Flutter run key commands.
   r Hot reload. 🔥🔥🔥
   R Hot restart.
   h List all available interactive commands.
   d Detach (terminate "flutter run" but leave application running).
   c Clear the screen
   q Quit (terminate the application on the device).
   ```

---

## Step 10: Using the App

Once the app launches on the simulator:

### Testing Wellness Goals:
1. You'll start on the **Goals** tab
2. Tap the **"Add Goal"** button (bottom right)
3. Fill in the form and save
4. Use the increase/decrease buttons to track progress

### Testing Videos:
1. Tap the **Videos** tab at the bottom
2. Browse the wellness videos
3. Tap any video to watch it
4. Try the search bar and category filters

### Testing Meditation:
1. Tap the **Meditate** tab
2. Optionally select a timer (5, 10, 15, 20, or 30 minutes)
3. Tap a nature sound card (Ocean, Rain, Forest, etc.)
4. Control playback with the play/pause button
5. Adjust volume with the slider

---

## Useful Flutter Commands

### Hot Reload (while app is running)
Press `r` in the terminal - this updates the UI instantly without restarting!

### Hot Restart (while app is running)
Press `R` - fully restarts the app

### Stop the App
Press `q` in the terminal

### Run in Release Mode (faster)
```bash
flutter run --release
```

### View Connected Devices
```bash
flutter devices
```

### Clean Build (if you have issues)
```bash
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### Error: "No devices found"
- Make sure the iOS Simulator is running
- Run: `open -a Simulator`

### Error: "CocoaPods not installed"
```bash
sudo gem install cocoapods
pod setup
```

### Error: Xcode build failed
```bash
cd ios
pod install
cd ..
flutter run
```

### Error: "flutter: command not found"
- Flutter wasn't added to PATH correctly
- Re-run the PATH export command from Step 1B

### App crashes on launch
- Check the terminal for error messages
- Try: `flutter clean && flutter pub get && flutter run`

---

## Running on a Physical iPhone

1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. Open Xcode, go to **Preferences** → **Accounts** → Add your Apple ID
4. Run: `flutter run`
5. Select your iPhone when prompted

---

## Next Steps After First Run

- Explore the code in VS Code or Android Studio
- Try modifying colors in `lib/core/theme/app_theme.dart`
- Add your own wellness goals
- Check out the BLoC pattern implementation

---

## Quick Reference

| Command | What it does |
|---------|--------------|
| `flutter doctor` | Check Flutter setup |
| `flutter pub get` | Install dependencies |
| `flutter run` | Run the app |
| `flutter clean` | Clean build artifacts |
| `r` (while running) | Hot reload |
| `q` (while running) | Quit app |

---

## Need Help?

- Flutter Documentation: https://docs.flutter.dev
- Flutter Community: https://flutter.dev/community
- Your project README: [README.md](file:///Users/ifthikaraliseyed/Downloads/project-gf-mobile/README.md)

Good luck! 🚀
