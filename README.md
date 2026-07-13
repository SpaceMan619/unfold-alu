# Unfold

Unfold is an Android-first Flutter application for opportunity discovery within
the African Leadership University community. Students can find roles, understand
why their skills fit, save listings, apply, and track progress. Founders can
publish paid, unpaid, or volunteer opportunities and manage an applicant
pipeline from the same account.

The differentiator is explainable CV matching. Firebase AI Logic extracts
editable skills from a selected PDF. A deterministic local matcher then compares
those skills with each role, so the percentage and evidence list can be explained
without allowing AI to accept or reject anyone.

![Unfold opportunity feed](docs/screenshots/final-home.png)

## Version 1.0 feature set

- ALU-domain Google sign-in plus email/password authentication
- Student onboarding and an accessible Founder Studio switch
- Real-time Firestore opportunities, applications, bookmarks, and profiles
- Search, category filters, paid/unpaid filters, and saved opportunities
- Explainable skill-match percentages with a visible skill-by-skill breakdown
- Validated application form and student application timeline
- Founder opportunity create, edit, close, and delete flows
- Paid/unpaid status, RWF or USD monthly compensation, and contact email
- Optional founder deadlines stored as Firestore timestamps
- Founder applicant states: submitted, reviewing, shortlisted, waitlisted,
  accepted, and rejected
- Applicant and organisation email composer actions
- PDF CV analysis through Firebase AI Logic with App Check
- Editable extracted skills, public-profile fields, and cropped profile photos
- Pull-to-refresh and real-time repository streams
- Custom Unfold launcher icon, splash screen, and glass-inspired visual system

## Honest prototype boundaries

- The bundled opportunity catalogue uses sourced venture names with fictional
  roles. It is a fallback for presentation and is not a live vacancy feed.
- Fallback opportunities never display fabricated deadlines. Deadline labels
  appear only when the Firestore opportunity document contains a timestamp.
- Founder Studio seeds three clearly labelled fictional applicants into the real
  `applications` schema when a founder has no applicants. Their status changes
  persist; real applicants replace them in the visible pipeline.
- CV bytes are processed from memory and are not retained in Cloud Storage. Only
  the structured analysis is stored in the authenticated user document.
- FlutterFire configuration and release verification currently target Android.

## Architecture

```text
Flutter widget
  -> Riverpod provider/controller
      -> repository interface
          -> Firebase Authentication / Cloud Firestore / Firebase AI Logic
```

Important choices:

- Widgets own short-lived presentation state such as search text.
- Riverpod notifiers coordinate session, opportunity, application, and CV state.
- Repository interfaces keep Firestore syntax out of UI widgets.
- Firestore streams make opportunity and application changes real time.
- Match calculations are cached until CV skills or opportunity data changes.
- Match rings use static custom paint instead of scroll-triggered animations.
- `GlassSurface` uses static gradients, borders, and highlights rather than live
  backdrop blur, keeping the Android scrolling path lightweight.

## Firestore schema

```text
users/{uid}
  name, email, role, bio, location, classYear, website
  skills[], interests[], profilePhotoBase64
  cvAnalysis { skills[], suggestedRoles[], summary }

opportunities/{opportunityId}
  ownerId, role, startupName, summary, location, commitment
  skills[], status, opportunityType, contactEmail
  isPaid, monthlyAmount, currency, deadline?

applications/{applicationId}
  opportunityId, studentId, founderId
  motivation, availability, portfolioUrl
  studentName, studentEmail, roleTitle, skills[], status, isDemo

bookmarks/{uid}/items/{opportunityId}
  savedAt
```

`deadline` is optional and must be a Firestore timestamp when present. Local
fallback opportunities keep it null, so urgency labels reflect persisted data.

## Project structure

```text
lib/
├── app/                    # app root and theme
├── core/widgets/           # reusable visual primitives
├── features/
│   ├── applications/       # model, form, repository, founder review
│   ├── auth/               # authentication, session, and onboarding
│   ├── cv/                 # PDF validation and Firebase AI analysis
│   ├── home/               # shell, views, sheets, and shared widgets
│   ├── opportunities/      # model, matching, seed data, repository
│   └── profile/            # public profile and image processing
├── firebase_options.dart
└── main.dart
test/                       # model, controller, repository, and widget tests
docs/                       # report, script, study guide, and sources
android/                    # Android host and branding
```

## Run and verify

Requirements: Flutter/Dart compatible with `sdk: ^3.11.5`, Java 17, Android
SDK, and an Android emulator or physical device.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run -d <device-id>
```

Build the smaller phone-specific release:

```bash
flutter build apk --release --split-per-abi
```

For a modern Android phone, use
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. ABI splitting reduces
download size without reducing image or rendering quality.

## Firebase setup

The included client configuration points to project `unfold-f52a4` and package
`com.alu.unfold.unfold`. Firebase client identifiers are public configuration;
service-account files, signing keys, AI-provider secrets, and App Check debug
tokens must never be committed.

For a replacement project:

1. Register the Android package and add debug/release SHA fingerprints.
2. Enable Google and Email/Password Authentication.
3. Create Cloud Firestore.
4. Enable Firebase AI Logic with the Gemini Developer API.
5. Configure App Check: debug provider for development and Play Integrity for
   release builds. Sideloaded builds require the approved unrecognized-version
   policy while retaining device integrity.
6. Run `flutterfire configure --platforms=android`.
7. Deploy `firebase deploy --only firestore:rules,firestore:indexes`.

## Data, privacy, and attribution

CVs contain personal information. Unfold requires explicit PDF selection,
accepts PDF files only, rejects files larger than 8 MB, keeps raw bytes in
memory, and stores only editable structured output. Matching recommends roles;
founders remain responsible for every hiring decision.

Fallback venture attribution and the fictional-data boundary are documented in
[docs/DEMO_DATA_SOURCES.md](docs/DEMO_DATA_SOURCES.md). Security guidance is in
[SECURITY.md](SECURITY.md).

## Submission material

- [Technical report](docs/TECHNICAL_REPORT.md)
- [10-minute demonstration script](docs/DEMO_SCRIPT.md)
- [Codebase study guide](docs/STUDY_GUIDE.md)
- [Submission checklist](docs/SUBMISSION_CHECKLIST.md)
- [Project guide](PROJECT_GUIDE.md)

Unfold is an educational prototype built for Mobile Application Development. It
demonstrates authentication, cloud persistence, role-aware workflows, CRUD,
real-time updates, validation, responsible AI, security rules, state management,
testing, and performance-aware Flutter UI design.
