# Unfold submission checklist

Use this as the final gate. Do not submit until every required item is checked or explicitly explained as a limitation.

## 1. Application quality

- [ ] Run the student journey on Android: sign in, browse, filter, open, apply, and track.
- [ ] Run the founder journey: sign in, publish an opportunity, view an applicant, and update status.
- [ ] Confirm Google sign-in accepts an authorized ALU account.
- [ ] Confirm loading, empty, validation, and Firebase error states are readable.
- [ ] Confirm no prototype-only feature is described as live.
- [ ] Confirm sourced fallback vacancies are visibly identified as fictional where required.
- [ ] Restart the app and verify Firebase-backed data still exists.

## 2. Code verification

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

- [ ] Formatting passes.
- [ ] Static analysis reports no issues.
- [ ] All tests pass.
- [ ] Android APK builds successfully.
- [ ] The APK installs and opens on the presentation device/emulator.

Expected APK: `build/app/outputs/flutter-apk/app-debug.apk`.

## 3. Firebase Console evidence

- [ ] Open Firebase Storage once, click **Get started**, then run `firebase deploy --only storage`.

- [ ] Authentication shows Email/Password and Google providers.
- [ ] Student and founder users exist for the demo.
- [ ] Firestore contains app-created `users`, `opportunities`, and `applications` documents.
- [ ] A status update is visible in an application document.
- [ ] Firestore rules/indexes and Storage rules are deployed.
- [ ] No service-account key or AI-provider secret is committed.
- [ ] Screenshots redact emails, UIDs, CVs, tokens, and credentials.

```bash
firebase use
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 4. GitHub repository

- [ ] Visibility matches the lecturer's instructions.
- [ ] README, project guide, rules, indexes, tests, and source are included.
- [ ] `build/`, IDE caches, local environment files, service-account JSON, and secrets are ignored.
- [ ] `git status` contains only intentional changes.
- [ ] The final commit is pushed.
- [ ] Open the URL in a private window to confirm assessor access.
- [ ] Copy the exact repository URL into the submission form/report.

Suggested repository name: `unfold-flutter`.

## 5. Technical report PDF

Follow the brief's exact naming/page rules. If none are specified, use:

```text
Rajveer_Singh_Jolly_Unfold_Technical_Report.pdf
```

- [ ] Title page includes student name/ID, module, lecturer, app name, and date.
- [ ] Problem, target users, and differentiator are clear.
- [ ] Architecture and Firestore schema are explained.
- [ ] Authentication, CRUD, real-time updates, state management, and security are evidenced.
- [ ] Design decisions and accessibility/performance trade-offs are discussed.
- [ ] Testing approach and actual results are included.
- [ ] Public prototype-data sources are cited.
- [ ] AI/CV work is described honestly as implemented, scaffolded, or future work.
- [ ] Limitations, privacy risks, and next steps are included.
- [ ] GitHub and demo-video URLs are clickable.
- [ ] Every exported PDF page is visually checked.

## 6. Demonstration video

If no naming pattern is supplied, use `Rajveer_Singh_Jolly_Unfold_Demo.mp4`.

Suggested recording order:

1. State the problem and product pitch.
2. Sign in with an ALU Google account.
3. Show role-aware onboarding/navigation.
4. Demonstrate discovery and filters.
5. Explain that personalized matches unlock after CV/skill evidence.
6. Submit a student application.
7. Switch to a founder account and publish an opportunity.
8. Review the application and change its status.
9. Return to the student flow and show the update.
10. Show Firebase Authentication and Firestore evidence.
11. Explain the Riverpod/repository design and responsible-AI roadmap.

- [ ] Duration fits the brief.
- [ ] Text and audio are clear; notifications are disabled.
- [ ] No password, API key, CV, private email, or token appears.
- [ ] Final video plays end-to-end after upload.
- [ ] Sharing permits assessor access without a request.

## 7. APK and hand-in package

If no APK naming rule is supplied, copy and rename it to `Rajveer_Singh_Jolly_Unfold.apk`.

- [ ] Install the exact renamed APK once.
- [ ] Keep APK, PDF, and MP4 filenames simple and consistent.
- [ ] Do not zip unless the portal or brief requires it.
- [ ] Upload early enough to verify every transferred file.
- [ ] Save submission confirmation and links separately.

## Final five-minute check

- [ ] Repository link works.
- [ ] Video link works.
- [ ] PDF opens.
- [ ] APK installs.
- [ ] Firebase demo accounts work.
- [ ] Filenames and student details are correct.
- [ ] Submission confirmation is saved.
