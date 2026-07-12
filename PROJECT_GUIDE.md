# Unfold project guide

Unfold connects ALU students with verified student-led ventures. Founders submit
a startup profile, publish clearly paid or unpaid opportunities, and review
applicants. Students discover roles, save them, apply, and track decisions.

## State flow

`SessionController` owns authentication and role state. Feature controllers own
opportunities, bookmarks, applications, CV analysis, and profile-photo updates.
Widgets read Riverpod providers; repositories isolate Firebase Authentication
and Firestore access, while Firebase AI Logic handles local PDF analysis.

## Firebase data

- `users`: role, public profile fields, compressed avatar, and CV analysis.
- `startups`: founder-owned profiles and administrator verification status.
- `opportunities`: role details, compensation, owner, skills, and status.
- `applications`: form answers and founder-controlled review status.
- `bookmarks/{userId}/items`: private saved opportunities.

Bundled venture logos live in `assets/logos`. The profile header is a generated
Flutter gradient, so it uses no storage. Sourced fallback opportunities keep an
empty Firestore project useful without displaying placeholder language.

## AI boundary

PDF selection sends local bytes through Firebase AI Logic using the Gemini
Developer API. No provider key is embedded in Flutter and no Storage bucket is
required. App Check protects the direct client request.
