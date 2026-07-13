# Unfold 10-Minute Demo Script

This script is paced for 9 minutes 30 seconds to 10 minutes. Do one practice recording. Keep the Android phone mirrored, Firebase Console open to Authentication and Firestore, and the code editor ready at the named files.

## Before recording

- Install the final V1 APK and sign out.
- Use an ALU Google account whose profile already contains a working CV analysis.
- Keep one founder-owned opportunity with a real Firestore deadline and one application ready; use prepared records to stay on time.
- Keep a small non-sensitive PDF CV ready. Hide private tabs and notifications.
- Open Firebase Console to Authentication, `users`, `opportunities`, and `applications`.
- Open `discover_view.dart`, `opportunity_match.dart`, and `opportunity_controller.dart` in VS Code.

## 0:00-0:35 - Product and problem

**Show:** Welcome screen.

"Unfold is a Flutter opportunity platform for the African Leadership University community. Students currently find practical roles through fragmented channels, while student founders often lack a structured applicant pipeline. Unfold combines discovery, CV-assisted matching, applications, publishing, and review in one role-aware mobile experience."

Point out the ALU image, rotating message, neutral visual identity, and reachable actions.

## 0:35-1:05 - Authentication and session state

**Show:** Continue with Google, account selection, restored session.

"Authentication uses Firebase Authentication with Google and email/password. Google onboarding is limited to ALU student and education domains. `SessionController` observes authentication changes and restores the Firestore user profile. `AuthGate` then renders one explicit state: loading, signed out, role selection, onboarding, or authenticated."

**Switch briefly to Firebase Console -> Authentication.** Show the same account without exposing unrelated data.

"This Firebase user is the identity currently driving the app. The session survives an app restart because Firebase restores it and the controller reloads the profile."

**Do not open the code yet.** Keep the first half focused on the product.

## 1:05-1:55 - Discovery, search, and UI reasoning

**Show:** Discover feed. Pull to refresh, search, select a category and paid filter, then open a role.

"The discovery screen combines a Firestore opportunity stream with local search and filters. Search covers title, venture, description, location, and skills. Cards surface the first-glance facts a student needs: venture, role, work arrangement, compensation, deadline when one exists, and match evidence."

"The design is glass-inspired rather than an iOS copy. I use a neutral base, static translucent layers, venture accent colors, large touch targets, and a draggable pill navigator. Physical-device testing showed that live blur and repeated number animations caused jitter, so version 1.0 uses static paint layers and static match rings."

## 1:55-2:25 - Real deadlines and opportunity details

**Show:** A Firestore-backed role with a deadline, then Firebase Console `opportunities/{id}`.

"The deadline is not prototype text. The founder selects it during publishing, the repository stores it as an optional Firestore timestamp, and the app calculates only the display label from that value. The security rule accepts a timestamp or null. Local fallback opportunities never invent deadlines, so if the backend has no deadline, the UI shows none."

Point to `deadline` in Firebase Console and return to the detail sheet. Show skills, compensation, contact action, and related roles.

## 2:25-3:15 - Saving and applying

**Show:** Save and unsave a role. Start an application, trigger validation, fill it, and submit.

"Bookmarks are private per-user documents. Unsave removes the item immediately and the stream confirms the change. Starting an application only opens a form. Firestore is written after required motivation and availability fields pass validation."

"The application stores student ID, opportunity ID, founder ID, answers, and the initial `submitted` state. The controller updates optimistically for responsiveness and rolls back if the repository write fails."

**Show:** Applications tab and the submitted item.

## 3:15-4:05 - CV intelligence and explainable matching

**Show:** Profile -> CV Intelligence. Choose the prepared PDF, analyze, then remove one extracted skill.

"This is Unfold's main differentiator. The picker accepts one readable PDF up to 8 MB. Firebase AI Logic sends the PDF inline to Gemini with a strict JSON schema for skills, suggested roles, and a one-sentence summary. The instruction extracts only evidence in the document and avoids sensitive-trait inference."

"The raw CV is not stored in Cloud Storage. Only the filename and editable structured result are merged into the authenticated user document. The match percentage is then deterministic: matched required skills divided by total required skills. AI does not accept or reject anyone."

Return to Discover and show that the evidence affects match rings.

## 4:05-4:45 - Founder Studio and CRUD

**Show:** Profile role toggle -> Founder Studio. Open a prepared opportunity with its paid/unpaid choice, amount/currency, email, and deadline.

"Founder Studio demonstrates the same backend from the other side. Creating a role writes an owner-linked document. Paid roles require a positive monthly amount and RWF or USD. The founder can edit, close, or remove their own listing."

Open applicant management, change a prepared applicant from submitted to reviewing or shortlisted, and tap email.

"Applications have six states: submitted, reviewing, shortlisted, waitlisted, accepted, and rejected. `ApplicationReviewController` changes the local item first and restores the old state if Firestore rejects the update. The contact action opens the device mail client with the opportunity context."

Finish the phone workflow before opening VS Code.

## 4:45-5:25 - Firebase CRUD and security evidence

**Show:** Firestore `opportunities` and `applications`; refresh the relevant document.

"Here is the opportunity created by the app, including its owner and timestamp deadline. Here is the application status that just changed. Snapshot listeners propagate these persistent changes back through repositories and Riverpod."

**Show:** `firestore.rules`.

"The UI is not the security boundary. A student may submit only as themselves and only with submitted status. For live opportunities, the founder ID must equal the opportunity owner. Only that owner or an administrator may change application status, and the relationship IDs cannot be replaced. Bookmark paths are private to their user."

## 5:25-5:50 - Start the code walkthrough

**Switch to VS Code now.** Use `Cmd + P` to open each file by its exact path. Do not browse the whole project tree during the recording.

Open `lib/features/auth/session_controller.dart`.

Say: "This controller listens to Firebase authentication, restores the matching profile, and exposes the session stages that drive `AuthGate`. The comment above the class marks the identity boundary I just demonstrated."

Open `lib/features/opportunities/opportunity_controller.dart`.

Say: "This controller combines the live opportunity stream with saved and applied state. Widgets call the controller instead of writing Firestore directly."

## 5:50-8:40 - Architecture, state propagation, and optimization

**Show:** Architecture diagram, then relevant code.

"The dependency flow is view, Riverpod controller, repository interface, then Firebase implementation. Widgets do not contain Firestore queries. Repositories make the backend replaceable and let tests use fakes."

**Open:** `lib/features/home/views/discover_view.dart`, then locate `_refreshOpportunityCache`.

"This short comment marks the important performance boundary: match and normalized search caches refresh only when skills or opportunity data changes. Scrolling rebuilds visible widgets but does not recalculate every percentage. Pull-to-refresh invalidates the live providers and new data changes the cache signature."

**Open:** `lib/features/opportunities/opportunity_match.dart` and `lib/core/widgets/match_ring.dart`.

"The matching function is a small pure calculation, which is easy to test. The ring only paints the result, so it does not restart an animation as cards enter the viewport. These changes came directly from profiling the physical-device experience."

**Open:** `lib/core/widgets/glass_surface.dart`.

Say: "This reusable widget supplies the rounded surface, border, gradient, shadow, and touch response used across the app. It keeps the glass-inspired visual language consistent without expensive full-screen blur."

**Open:** `lib/features/cv/cv_analysis_controller.dart`.

Say: "This is the AI path: it limits the PDF, sends it through Firebase AI Logic, requires structured JSON, and saves only editable results to the user's Firestore document."

**Open:** `lib/features/applications/application_review_controller.dart`.

Say: "This controller owns founder-side applicant state and performs an optimistic status update with rollback if Firebase rejects the write."

## 8:40-9:45 - Testing, limitations, and conclusion

**Show:** terminal results for `flutter analyze` and `flutter test`.

"Tests cover models, authentication restoration, onboarding, search and filters, opportunity creation, deadline rendering, application validation, optimistic founder review, matching, and key widget flows. Riverpod overrides replace Firebase with controlled fakes. Static analysis passes before release."

"Current limits are clear: fallback roles are demonstration content, email uses the external mail client, there is no institution-admin mobile panel, and production would need wider accessibility, App Check, rule-emulator, and device testing."

Close with:

"Unfold turns a fragmented ALU opportunity process into one understandable student-to-founder workflow. It combines persistent Firebase data, explainable AI-assisted evidence, role-aware state, and a visual system refined through real device feedback."

## Recovery lines

- If Google selection stalls: "The restored Firebase session and matching Authentication record demonstrate the same identity path, so I will continue from the signed-in state."
- If AI quota or App Check fails: "The controller maps this backend failure to a readable state. I will show the previously persisted structured analysis in the user document."
- If a write fails: "This shows that Firestore rules are the final authority. I will explain the ownership condition and continue with the prepared record."
- If fallback roles appear: "Firestore currently has no active live items for this query, so the controller supplies clearly identified demonstration content with no fabricated deadlines."
- If recording runs long: skip related roles and the email-client launch; do not skip Firebase Console, architecture, or testing.
