# Unfold project guide

## Product

Unfold connects ALU students with opportunities from student- and alumni-led
ventures. Students discover, save, apply, and track. Founders publish roles and
move applicants through a clear review pipeline.

## Data flow

```text
view -> Riverpod controller -> repository -> Firebase
```

- `SessionController` restores authentication and the Firestore user profile.
- `OpportunityActivityController` combines live roles, fallback roles,
  bookmarks, and student applications.
- `ApplicationReviewController` streams founder applicants and persists status
  changes with optimistic rollback.
- `CvAnalysisController` validates a local PDF, invokes Firebase AI Logic, and
  stores editable structured evidence in the user document.
- Repository interfaces isolate Firestore and make controller tests possible.

The home library is divided into focused views, sheets, and widgets. Short-lived
UI values such as search text remain local; shared and persistent state belongs
to providers.

## Firebase data

- `users/{uid}`: identity, public profile, compressed avatar, and CV analysis.
- `opportunities/{id}`: owner, role, compensation, skills, status, and optional
  deadline timestamp.
- `applications/{id}`: student/founder relationship, form answers, and review
  status.
- `bookmarks/{uid}/items/{opportunityId}`: private saved roles.

Fallback roles are local presentation data. They never receive generated
deadlines. A deadline appears only when it exists in a Firestore opportunity.

## Matching

Firebase AI Logic converts a PDF into skills, suggested roles, and a summary.
The local matcher compares normalized profile skills with each opportunity's
skills. It produces a percentage and the exact matched/missing evidence shown in
the interface. Results are cached until skills or opportunity data changes, and
AI never makes an application decision.

## Performance

- Match rings use static custom paint rather than replaying animations.
- Search text and match results are cached for the current opportunity dataset.
- The rotating slogan owns its own widget state, so it does not rebuild the feed.
- Glass depth uses static paint layers instead of live Android backdrop blur.
- Images use bounded decode sizes and the release APK is split by ABI.

## Presentation boundary

Venture names and logos are sourced; fallback vacancies and demo applicants are
fictional and identified as such. Real authentication, profiles, bookmarks,
opportunities, applications, CV analysis, and founder status updates persist in
Firebase.
