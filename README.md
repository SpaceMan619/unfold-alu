# Unfold

Unfold is an Android-first Flutter application that connects African Leadership University students with opportunities from student- and alumni-led ventures. Students can discover roles, filter the opportunity feed, save listings, submit applications, and track progress. Founders can publish opportunities and review applicants from a role-aware workspace.

Its planned differentiator is **explainable CV matching**: the interface supports PDF selection and deliberately withholds personalized scores until a student provides evidence. Automated CV analysis is scaffolded as a future service; it is not presented as completed AI.

## Current status

### Implemented

- Android Flutter application with a custom dark, glass-inspired visual system
- ALU-domain Google sign-in and email/password account creation
- Student and founder role selection and onboarding
- Firestore-backed user profiles
- Real-time Firestore opportunity feed with sourced prototype seed content as fallback
- Search and category filters
- Opportunity details, save state, and application form
- Firestore-backed student applications and founder status updates
- Founder opportunity publishing
- PDF CV selection UI and CV-analysis state scaffold
- Riverpod state management
- Firestore and Storage security rules
- Widget, controller, model, and form tests
- Explicit paid/unpaid listings with RWF or USD monthly compensation
- Social-style external profile with bounded, cropped profile-photo upload
- Pull-to-refresh across student and founder pages

### Partial or planned

- Saved opportunities persist per user in Firestore, with optimistic UI and a local fallback when the backend is unavailable.
- Opportunity repository methods support update and delete, but the current founder UI focuses on publishing.
- Founders can submit startup profiles and publishing is gated by verification; verification itself is performed by an administrator in Firebase Console.
- CV upload to Firebase Storage and server-side AI extraction are not implemented.
- Match scores in sourced fallback records are presentation fields. The UI does not expose them as personalized matches until CV/skill evidence exists.
- FlutterFire configuration is Android-only.

## Architecture

Unfold uses a small feature-first structure so the data flow stays explainable:

```text
widget
  -> Riverpod controller/provider
      -> repository interface
          -> Firebase Auth / Cloud Firestore
```

Key choices:

- **Flutter + Material 3** for the Android client
- **Riverpod** for session and feature state
- **Firebase Authentication** for Google and email/password sign-in
- **Cloud Firestore** for users, opportunities, and applications
- **Firebase Storage** rules prepared for CVs and startup assets
- Repository boundaries keep Firebase calls out of most widgets
- Firebase streams update opportunity and application views in real time

Firestore collections used or defined by the project:

```text
users/{userId}
startups/{startupId}
opportunities/{opportunityId}
applications/{applicationId}
bookmarks/{userId}/items/{opportunityId}
```

See [PROJECT_GUIDE.md](PROJECT_GUIDE.md) for a concise walkthrough.

## Project structure

```text
lib/
├── app/                    # root app and visual theme
├── core/                   # backend configuration and shared widgets
├── features/
│   ├── applications/       # form, model, repository, founder review
│   ├── auth/               # Firebase auth and onboarding
│   ├── cv/                 # PDF selection and AI-ready state scaffold
│   ├── home/               # student/founder shells and screens
│   └── opportunities/      # model, seed data, repository, controller
├── firebase_options.dart   # generated Android Firebase options
└── main.dart
test/                       # widget, model, form, and controller tests
docs/                       # source notes and submission material
android/                    # Android host project and Google services config
```

## Requirements and local run

- Flutter SDK compatible with Dart `^3.11.5`
- Android SDK and an emulator or physical Android device
- Java 17
- A Firebase project when replacing the included configuration
- Firebase CLI and FlutterFire CLI for backend reconfiguration

```bash
flutter doctor -v
flutter devices
flutter pub get
flutter analyze
flutter test
flutter run
```

To select a device and build an APK:

```bash
flutter run -d <device-id>
flutter build apk --debug
```

The APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## Firebase setup

The checked-in Android configuration targets Firebase project `unfold-f52a4` and application ID `com.alu.unfold.unfold`. Firebase web API keys and `google-services.json` identify the client; they are not server-side admin credentials. Never add service-account JSON or AI-provider secrets to Git.

For another Firebase project:

1. Register an Android app with package name `com.alu.unfold.unfold`.
2. Enable **Authentication > Sign-in method > Email/Password** and **Google**.
3. Add development/release SHA fingerprints required by Google sign-in.
4. Create Cloud Firestore and Firebase Storage.
5. Regenerate Android configuration and deploy rules:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android
firebase deploy --only firestore:rules,firestore:indexes,storage
```

6. Confirm `lib/firebase_options.dart`, `android/app/google-services.json`, `.firebaserc`, and `firebase.json` point to the intended project.

Current Firestore rules restrict new database profiles to authenticated ALU addresses ending in `@alustudent.com` or `@alueducation.com`. Google sign-in performs the same domain check in the client.

## Demo account guidance

No passwords or reusable accounts belong in Git. For an assessment demo:

- prepare one student and one founder account using authorized ALU-domain addresses;
- use unique, non-reused passwords;
- confirm each has a `users/{uid}` profile with the correct role;
- create at least one founder-owned opportunity before recording;
- submit one student application and demonstrate a founder status change;
- redact email addresses, UIDs, tokens, and personal documents from screenshots.

If an assessor cannot use an ALU-domain account, demonstrate with pre-created authorized accounts instead of weakening rules immediately before submission.

## Prototype data and attribution

Fallback venture names and public founder information were assembled from public ALU sources. **All opportunity titles, requirements, deadlines, locations, match values, and vacancy status in the seed set are fictional prototype data.** They must not be described as real vacancies or endorsements.

Citations and usage constraints are in [docs/DEMO_DATA_SOURCES.md](docs/DEMO_DATA_SOURCES.md).

No repository screenshot assets currently exist, so this README intentionally does not display placeholder or unrelated images.

## Privacy and responsible AI roadmap

CVs contain personal data. A production CV-analysis release should:

- obtain explicit consent before upload and analysis;
- keep provider keys in a trusted backend such as Cloud Functions secrets;
- validate file type/size and scan untrusted uploads;
- minimize retention and let students delete original and extracted data;
- show extracted skills for review and correction;
- explain matches without allowing AI to accept or reject applicants;
- document processing providers and retention terms;
- provide a manual fallback when analysis is unavailable.

The current code only selects a local PDF and models analysis states. It does not upload or send a CV to an AI provider.

## Assignment context

Unfold was developed as a Mobile Application Development assignment. It demonstrates authentication, role-aware flows, CRUD/repository design, persistent cloud data, real-time updates, validation, state management, security rules, testing, and a domain-specific concept. It is an educational prototype, not a live recruitment service.

Before hand-in, complete [docs/SUBMISSION_CHECKLIST.md](docs/SUBMISSION_CHECKLIST.md).
