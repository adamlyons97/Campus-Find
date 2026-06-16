# 🛠️ CampusFind — Setup & Run Guide

This guide takes you from a fresh clone to a running CampusFind app. It assumes
you are working in **VS Code** with the Flutter and Dart extensions installed.

---

## 1. Prerequisites

| Tool | Version | Check with |
|------|---------|-----------|
| Flutter SDK | 3.19+ (Dart 3.3+) | `flutter --version` |
| Firebase CLI | latest | `firebase --version` |
| FlutterFire CLI | latest | `flutterfire --version` |
| A device/emulator | Android API 23+ or iOS 13+ | `flutter devices` |

Install the Firebase tooling if you don't have it:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

---

## 2. Install Dart/Flutter dependencies

From the project root:

```bash
flutter pub get
```

---

## 3. Connect your Firebase project

CampusFind uses **Firebase Auth**, **Cloud Firestore**, and **Firebase Storage**.

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. In the console, enable:
   - **Authentication → Sign-in method → Email/Password**
   - **Firestore Database** (start in production mode; we deploy rules below)
   - **Storage**
3. From the project root, generate the platform config:

```bash
flutterfire configure
```

This overwrites the placeholder `lib/firebase_options.dart` with your real
project keys and adds the Android/iOS config files. **This step is required** —
the bundled `firebase_options.dart` only contains `REPLACE_ME` placeholders so
the project compiles before you connect a backend.

---

## 4. Supply the Gemini API key (never hard-coded)

The AI smart-match and AI search features use Google Gemini. The key is read at
build time via `String.fromEnvironment('GEMINI_API_KEY')`, so it is **not**
stored in source. Get a key from [Google AI Studio](https://aistudio.google.com/app/apikey),
then pass it with `--dart-define`:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

For a release build:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

> 💡 In VS Code you can avoid retyping this. Create `.vscode/launch.json` with a
> `"toolArgs": ["--dart-define=GEMINI_API_KEY=your_key_here"]` entry. The
> `.env` / `dart_define.json` patterns are already git-ignored.

If the key is missing the app still runs; the AI features degrade gracefully and
report that matching is unavailable rather than crashing.

---

## 5. Android minimum SDK

`firebase_auth` requires a higher `minSdk` than Flutter's default. In
`android/app/build.gradle` (or `build.gradle.kts`), ensure:

```gradle
defaultConfig {
    minSdkVersion 23   // firebase_auth needs >= 23
}
```

---

## 6. Deploy the Firestore security rules

The repo ships role-based rules in `firestore.rules` (claim approval is
restricted to `security`/`admin` roles, matching the Shariah verification flow).
Deploy them:

```bash
firebase deploy --only firestore:rules
```

---

## 7. Seed the item categories (one-time)

The `itemCategories` collection backs the category dropdown. You can add docs
manually in the Firestore console using the schema in the README (`name`,
`iconPath`), e.g. `Documents`, `Electronics`, `Keys`, `Cash`. Default seed
values are defined in `lib/data/models/category_model.dart` for reference.

---

## 8. Run

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Register with a university email (`@live.iium.edu.my` or `@iium.edu.my`) — other
domains are rejected by design (Feature 1).

---

## 9. Run the tests

```bash
flutter test
```

This runs the pure-Dart validator tests in `test/validators_test.dart` (no
Firebase needed).

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Missing firebase_options.dart values` / init error | You skipped step 3 — run `flutterfire configure`. |
| AI features say "unavailable" | `GEMINI_API_KEY` not passed — see step 4. |
| Android build fails on `firebase_auth` | Bump `minSdkVersion` to 23 — see step 5. |
| `permission-denied` writing claims | Deploy the rules (step 6) and confirm your user `role`. |
