# Security notes

## Client configuration

The values in `android/app/google-services.json` and `lib/firebase_options.dart` identify the Firebase Android client. Firebase documents these client API keys as public by design. The Unfold Android key is restricted to Firebase-related APIs and does not allow the Generative Language API.

Authorization is enforced with Firebase Authentication, Firestore Security Rules, and Firebase App Check. A Firebase client key must never be treated as a replacement for those controls.

## Secrets that must stay local

Never commit:

- service-account JSON files;
- Gemini Developer API or other provider keys;
- App Check debug tokens;
- signing keystores or `key.properties`;
- `.env` files containing credentials.

The repository ignores the relevant local files. Debug builds use the App Check debug provider and release builds use Play Integrity, so a debug token is not compiled into a release APK.

## Reporting

If a real credential is exposed, revoke it at the provider first, remove it from the current tree and Git history as appropriate, and then resolve the GitHub secret-scanning alert with an accurate reason. Do not paste credential values into issues or commit messages.
