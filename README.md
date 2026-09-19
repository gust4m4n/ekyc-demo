# eKYC Demo

A Flutter application (Android + iOS) that walks a user through a complete
**electronic Know Your Customer (eKYC) onboarding flow**: consent, identity
details, address, identity document photos, a selfie and a face liveness video,
followed by a review screen and a simulated submission.

Everything runs locally on the device — no backend, no network calls. The draft
is kept in memory for the duration of the session, and the captured media is
deleted from disk when the session is cleared or the app is disposed.

## The flow

The app opens directly on step 1. Every step shares the same chrome: title,
`Step n of 7` counter, progress bar and a pinned action bar.

| Step | Screen           | What happens                                                                                     |
| ---- | ---------------- | ------------------------------------------------------------------------------------------------ |
| 1    | Consent          | Explains what will be collected and which documents the selected market accepts; records opt-in. |
| 2    | Identity details | Document type, document number, names, birth date and place, nationality, occupation, expiry.    |
| 3    | Address          | Street line plus province / city / district dependent dropdowns and postal code.                 |
| 4    | Document photo   | Camera capture of the front side (or passport data page) and, when applicable, the back side.    |
| 5    | Selfie           | Front-camera capture with a face-oval guide.                                                     |
| 6    | Liveness video   | Face challenges recorded as a short clip (see below).                                            |
| 7    | Review           | Summary of everything captured, with a shortcut back to any step, then `Submit demo`.            |
| —    | Success          | Shows a generated `DEMO-########` reference and offers to erase the session data.                |

Every field is validated against the rules of the active market, and document
numbers are masked (`32••••••••1234`) when shown back to the user.

## Liveness detection

Step 6 is powered by `packages/liveness_sdk`, a self-contained module bundled in
this repository. It opens a full-screen selfie camera and prompts the user to
**smile**, **blink** and **turn right**, validating each prompt on device with
Google ML Kit Face Detection (smile probability, eye-open probability for blink
counting, head yaw angle for the poses).

The whole session is recorded. Once every challenge passes, FFmpeg rotates the
clip upright, mirrors it to match the selfie preview and scales it down before
handing the file back. If the user backs out or the 15s window expires, the step
reports that the session was cancelled or timed out and offers a retry.

The app tunes the module through `LivenessConfig` and `LivenessTheme` in
[lib/theme/brand.dart](lib/theme/brand.dart):

```dart
final result = await const LivenessSdk(
  config: kLivenessConfig,
  theme: kLivenessTheme,
).start(context: context, expressions: kLivenessExpressions);

if (result != null) {
  // Verified — result.video holds the recorded clip.
}
```

See [packages/liveness_sdk/README.md](packages/liveness_sdk/README.md) for the
full reference. The package does not depend on the demo app, so it can be copied
into any other Flutter project as a path dependency.

## Country-agnostic configuration

Nothing about a market is hard coded. A `CountryProfile` describes the accepted
document types, the local name and regex rule for the national ID, the minimum
age, the address labels (province / state / emirate, city, district), the postal
code rule and the dial code. Adding a market is a data change in
[lib/config/country_profiles.dart](lib/config/country_profiles.dart) rather than
a code change.

Eight profiles ship with the demo (Indonesia, Malaysia, Singapore, the
Philippines, India, UAE, United Kingdom, United States) so every branch of the
address form is exercised. The selectable set is currently limited to Indonesia,
whose province, city and district lists come from
[lib/config/indonesia_regions.dart](lib/config/indonesia_regions.dart).

## Project layout

```
lib/
  main.dart            app entry point, theme and EKycScope wiring
  screens/             the seven step screens plus the success screen
  config/              country profiles, document types, region data
  models/              in-memory draft: consent, identity, address, media assets
  state/               EKycController (ChangeNotifier) and EKycScope
  camera/              shared full-screen capture page (card frame / face oval)
  widgets/             step scaffold, form fields, guidelines, video player
  theme/               brand palette, Material theme, liveness config
  utils/               formatting, masking and validation helpers
packages/
  liveness_sdk/        reusable face liveness module (see its own README)
android/ ios/          platform projects
assets/icon/           app icon / brand palette source
```

State lives in a single `EKycController` (`ChangeNotifier`) exposed to the widget
tree through `EKycScope`, an `InheritedNotifier`. Switching market clears the
identity and address data, since both were validated against the previous
country's rules.

## Key dependencies

| Package                          | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `camera`                         | Document/selfie capture and liveness recording  |
| `google_mlkit_face_detection`    | On-device face landmark and classification      |
| `ffmpeg_kit_flutter_new_min_gpl` | Rotate, mirror and downscale the liveness clip  |
| `path_provider`                  | Temporary/documents directory for the recording |
| `video_player`                   | Playback of the liveness clip                   |
| `gal`                            | Saving the clip to the device gallery           |

## Requirements

- Flutter with Dart SDK `^3.8.1`
- Android `minSdk 24` with core library desugaring enabled
- iOS 15.5 or newer
- A physical device — the flow needs real front and rear cameras

Permissions already declared: `CAMERA` (plus legacy storage for gallery export)
on Android, and `NSCameraUsageDescription` / `NSPhotoLibraryAddUsageDescription`
on iOS.

## Running

```bash
flutter pub get
flutter run
```

To build release artifacts:

```bash
flutter build apk --release
flutter build ios --release
```
