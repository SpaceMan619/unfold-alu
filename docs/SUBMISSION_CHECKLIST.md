# Unfold V1 Submission Checklist

## Application

- [ ] Install the exact final APK on a physical Android phone.
- [ ] Test Google sign-in, restored session, refresh, search, filter, save/unsave, details, and application submission.
- [ ] Analyze a non-sensitive PDF under 8 MB and verify editable skills affect matching.
- [ ] Publish one founder opportunity with compensation and a deadline.
- [ ] Change one applicant through the founder pipeline and verify persistence after restart.
- [ ] Confirm fallback roles show no fabricated deadline.
- [ ] Confirm portrait-only layout, profile editing, photo crop, logout, email links, and back/swipe sheet behavior.

## Source verification

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

- [ ] Formatting passes.
- [ ] Static analysis reports no issues.
- [ ] All tests pass.
- [ ] Release ARM64 APK builds, installs, and opens.
- [ ] `git status` contains only intentional submission files.

## Firebase Console evidence

- [ ] Authentication shows Google and Email/Password providers.
- [ ] `users` contains the demo identity and structured CV result.
- [ ] `opportunities` contains an app-created owner-linked record and timestamp deadline.
- [ ] `applications` shows the submitted record and status update.
- [ ] Firestore rules and indexes are deployed.
- [ ] No service-account key, provider key, debug token, keystore, or `.env` secret is committed.
- [ ] Recording hides passwords, tokens, private CV content, unrelated emails, and UIDs.

Storage is not required for V1. Do not upgrade solely for this submission. Raw PDFs are not stored, and photos use the existing compressed profile path.

## GitHub

- [ ] README describes only current features and boundaries.
- [ ] Technical report, diagrams, script, study guide, rules, indexes, tests, and source are included.
- [ ] Build output, local caches, secrets, and signing files are ignored.
- [ ] Final V1 commit is pushed.
- [ ] Repository URL opens for the assessor.

## Technical report

Required filename from the assignment:

```text
RajveerSinghJolly_FinalFlutterProject.pdf
```

- [ ] PDF explains architecture, Firebase schema, Riverpod, workflows, design reasoning, scalability, challenges, testing, limitations, and future work.
- [ ] IEEE-style references, diagrams, and current screenshots are present.
- [ ] AI, matching, fallback data, and deadlines are described accurately.
- [ ] Every rendered page has been visually checked for clipping or missing glyphs.

## Video

- [ ] Duration is 7-10 minutes; target 9:30-10:00.
- [ ] Demonstrate Authentication and Firestore Console changes in real time.
- [ ] Demonstrate student and founder state changes.
- [ ] Explain view -> controller -> repository -> Firebase.
- [ ] Explain cache invalidation and the static match ring.
- [ ] Show analysis/test results.
- [ ] State limitations without calling implemented work a prototype.
- [ ] Uploaded video plays end to end and sharing permits assessor access.

## Canvas final gate

- [ ] GitHub repository link works.
- [ ] Demo video link works.
- [ ] PDF opens and filename is correct.
- [ ] Exact APK is retained as backup.
- [ ] Submission confirmation is saved.
