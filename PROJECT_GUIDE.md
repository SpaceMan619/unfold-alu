# Unfold project guide

Unfold connects ALU students with verified student-led ventures. Founders submit
a startup profile, publish clearly paid or unpaid opportunities, and review
applicants. Students discover roles, save them, apply, and track decisions.

## State flow

`SessionController` owns authentication and role state. Feature controllers own
startup verification, opportunities, bookmarks, applications, CV selection,
and profile-photo upload. Widgets read Riverpod providers; repositories isolate
Firebase Authentication, Firestore, and Storage access.

## Firebase data

- `users`: role, public profile fields, and the Firebase Storage photo URL.
- `startups`: founder-owned profiles and administrator verification status.
- `opportunities`: role details, compensation, owner, skills, and status.
- `applications`: form answers and founder-controlled review status.
- `bookmarks/{userId}/items`: private saved opportunities.
- Storage `users/{uid}/profile/avatar.jpg`: cropped 1024px profile image.
- Storage `users/{uid}/cvs/`: reserved private CV objects.

Bundled venture logos live in `assets/logos`. The profile header is a generated
Flutter gradient, so it uses no storage. Sourced fallback opportunities keep an
empty Firestore project useful without displaying placeholder language.

## AI boundary

PDF selection and the secure callable-function boundary exist. AI analysis is
not represented as complete until the chosen provider secret is configured and
the Cloud Function is deployed on a billing-enabled Firebase plan.
