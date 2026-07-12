# Unfold 7–10 Minute Demo Script

## Before recording

- Start the Android emulator and run Unfold in release/profile mode if possible.
- Sign out so the welcome screen is visible.
- Keep Firebase Console open in a browser with Authentication and Firestore tabs ready.
- Prepare one ALU student account and, if available, one founder account.
- Ensure at least one opportunity/application is in Firestore, or clearly identify seed content.
- Do not claim that CV AI analysis works. Say it is the next-phase scaffold.

## 0:00–0:45 — Problem and product

**Show:** Welcome screen.

“Unfold is a mobile opportunity platform for the African Leadership University community. Students often discover project roles through fragmented channels, while student founders lack a consistent applicant pipeline. Unfold brings discovery, applications, and founder review into one trusted, role-aware experience.”

Mention the product promise: “meaningful work in the ALU community, with every application step visible.”

## 0:45–1:35 — Authentication and role-aware onboarding

**Show:** Continue with Google, then role selection.

“The app uses Firebase Authentication. Google sign-in accepts ALU student and education domains, and email/password is also supported. Authentication state is observed by `SessionController`. The `AuthGate` renders loading, signed-out, role-selection, onboarding, or authenticated UI from one explicit session state.”

Select **student**. Point out the reachable cards, validation, typography, and glass surface.

## 1:35–3:20 — Student discovery

**Show:** Discover screen, search, category filters, one opportunity detail.

“The discovery feed combines venture, role, location, commitment, and skills. Search runs across role, startup, description, and skills. Category chips apply a second filter and a purposeful empty state appears when nothing matches.”

Search for `Flutter`, clear it, then select **Technology**. Open an opportunity.

“Firestore active-opportunity snapshots flow through a repository into a Riverpod notifier. Screens do not call Firebase directly. If the live collection is empty, seed content keeps the prototype demonstrable.”

Point out that the interface says **Unlock your matches**, not a fake percentage.

“Unfold does not invent a personalized score before a student provides evidence.”

## 3:20–4:30 — Application workflow

**Show:** Start application, validation, completed form, submit, Applications tab.

Tap submit with required content missing to demonstrate validation, then enter a concise motivation and availability.

“The application document records the student ID, opportunity ID, owning founder ID, answers, and initial `submitted` status. The controller updates the interface optimistically, but rolls back if Firestore rejects the request.”

Submit and show the applications area.

## 4:30–5:15 — CV scaffold and honest AI scope

**Show:** Profile → CV intelligence → Choose PDF CV.

“This is the scaffold for Unfold's future differentiator: explainable CV-assisted matching. The implemented build safely selects a PDF and represents analysis stages, but it does not yet upload or call an AI model. The complete design would use Firebase Storage and a Cloud Function so the API key never enters Flutter. Students would review extracted skills before any matching.”

Select a PDF if one is available; show its selected state and removal.

## 5:15–6:25 — Founder workflow

**Show:** Preview founder experience, dashboard, create opportunity, applicant review.

“The founder studio summarizes active roles and applicants. Founders can publish opportunities and move their own applicants through submitted, reviewing, shortlisted, accepted, and rejected.”

Create a small role if the connected account is authorized as a founder. Otherwise show the prepared form without claiming a successful write. Open applicant review and change one status.

“`ApplicationReviewController` performs an optimistic state change and restores the old state on a failed repository write.”

## 6:25–7:30 — Firebase Console evidence

**Show:** Firebase Console → Authentication → Users.

“This is the authenticated ALU account used in the app.”

**Show:** Firestore → `users`, `opportunities`, `applications`.

“The user document stores profile and role. Opportunities store their owner ID. Applications store both student and founder IDs so each side can query its pipeline.”

**Show:** Rules tab or local `firestore.rules`.

“Security is enforced in Firebase, not only by hiding buttons. A student can submit only as themselves and only in `submitted` state. Only the owning founder or an administrator can change status. Relationship fields cannot be replaced during that update. Users can access only their own bookmark path.”

## 7:30–8:25 — Architecture and visual system

**Show:** Architecture diagram, then return to app navigation.

“The architecture is UI to Riverpod controller to repository to Firebase. Repository interfaces let tests substitute fakes and keep Firestore details outside widgets.”

“The visual system is Liquid Glass-inspired for Android. `GlassSurface` combines clipped localized blur, translucent gradients, borders, highlights, shadows, and Material ink response. Blur stays local to cards to control GPU cost. A floating pill navigation bar, strong editorial headings, and mint/amber accents create a recognizable Unfold identity.”

## 8:25–9:15 — Testing, limitations, and close

**Show:** terminal output for `flutter analyze` and `flutter test`, or a screenshot of it.

“Tests cover session restoration, onboarding validation, opportunity creation, application mapping and validation, and founder status changes. Riverpod overrides replace Firebase dependencies with controlled fakes.”

“The current limitations are transparent: bookmark persistence, full startup/admin verification UI, production security-rule emulator tests, and AI CV analysis remain future work. The foundation is intentionally separated so those additions do not require rebuilding the app.”

Close:

“Unfold turns a fragmented campus opportunity process into one clear student-to-founder workflow, backed by role-aware Firebase security and an interface designed specifically for the ALU community.”

## Likely live-demo recovery lines

- **If Firestore rejects a write:** “This demonstrates that the backend rule is the source of truth. I will show the exact ownership condition in the rules and continue with the existing record.”
- **If Google account selection stalls:** “Authentication was already demonstrated by this Firebase user record; I will continue from the restored session.”
- **If the feed shows seed content:** “The live stream is empty, so the controller intentionally supplies sourced seed content as a presentation fallback.”
- **If CV is questioned:** “Selection and state scaffolding are implemented; model analysis is future work and is not represented as complete.”
