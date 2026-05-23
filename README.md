# EXPY — Terminal Finance Tracker

## Build Instructions

### Option A: Codemagic (No PC needed)
1. Go to https://codemagic.io
2. Sign up free with GitHub/Google
3. Click "Add application" → upload this zip
4. Select Flutter → Android
5. Start build → download APK when done

### Option B: Local PC
Requirements: Flutter SDK, Android Studio (for SDK)

```bash
flutter pub get
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Phone
- Transfer APK to phone via USB / WhatsApp / Google Drive
- Enable "Install from unknown sources" in Settings → Security
- Tap the APK file to install

## App Features
- Monthly budget tracking
- Spending classes / categories
- Peer debt ledger (TO GIVE / TO TAKE) with carry-forward
- Savings pocket (separate from spending)
- 100% offline, no internet needed
- Pure terminal aesthetic
