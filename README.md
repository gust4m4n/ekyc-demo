# eKYC Demo

A Flutter application (Android + iOS) that walks a user through a complete
**electronic Know Your Customer (eKYC) onboarding flow** for the Indonesian
KTP: consent, a face liveness video, a selfie, a selfie holding the KTP, an OCR
scan of the KTP, a review of the extracted fields, then a single summary screen
and a simulated submission.

It is a **demo**, not a production verification product. It shows how the
capture, liveness and document-reading pieces of an onboarding journey fit
together on a phone; it does not open an account, call a bank, or check the
card against any government registry. The final screen returns a fake
`DEMO-########` reference.

## What it does

- **Proves presence first.** A recorded liveness session (smile, blink, turn
  right) is validated on device before a single photo is taken.
- **Captures three images.** A selfie, a selfie holding the KTP, and a photo of
  the card itself, each with a framing guide drawn over a full-screen camera.
- **Reads the card on device.** Google ML Kit OCR parses the printed labels
  into structured fields and face detection crops the holder's portrait.
- **Lets the user correct the scan.** Every field is prefilled and editable;
  unreadable fields are flagged instead of blocking the flow.
- **Ships two reusable modules.** `packages/liveness_sdk` and
  `packages/ktp_scanner` are self-contained path dependencies that can be
  copied into any other Flutter project.

The only identity data collected is what is printed on the KTP: the card is
read on device and the user corrects anything the scanner got wrong. No extra
forms, no address entry, no document type picker.

## Privacy

Everything runs locally on the device — no backend, no network calls, no
analytics. The draft is kept in memory for the duration of the session, and the
captured media is deleted from disk when the session is cleared or the app is
disposed. The NIK is masked on the summary screen and no sensitive value is
written to the application logs.

## The flow

The app opens directly on step 1. Every step shares the same chrome: title,
`Step n of 7` counter, progress bar and a pinned action bar.

| Step | Screen          | What happens                                                                              |
| ---- | --------------- | ----------------------------------------------------------------------------------------- |
| 1    | Consent         | Explains what will be collected and records the opt-in.                                   |
| 2    | Liveness video  | Face challenges recorded as a short clip (see below). Proof of presence comes first.      |
| 3    | Selfie          | Front-camera capture with a face-oval guide.                                              |
| 4    | Selfie with KTP | Front-camera capture with a head-and-card guide, tying the person to the card.            |
| 5    | KTP photo       | Rear-camera capture, then on-device OCR and portrait cropping via `packages/ktp_scanner`. |
| 6    | KTP details     | Every KTP field, prefilled from the scan and fully editable; unread fields are flagged.   |
| 7    | Review          | One screen with the video, both selfies, the card photo and the final field values.       |
| —    | Success         | Shows a generated `DEMO-########` reference and offers to erase the session data.         |

No field is mandatory and nothing is length-checked: a worn card does not
always read cleanly, so whatever the user leaves on step 6 is accepted as the
record. The NIK is masked (`32••••••••1234`) when shown back on the summary.

## Stored photos

OCR and the resolution check run against the full-resolution capture, but only
a downscaled JPEG is kept. [lib/utils/image_compressor.dart](lib/utils/image_compressor.dart)
bakes the EXIF rotation in, scales the photo to fit its bounds with the aspect
ratio preserved, and re-encodes it at 80% quality.

| Photo                   | Bounds     |
| ----------------------- | ---------- |
| Selfie, selfie with KTP | 768 × 1024 |
| KTP                     | 1024 × 768 |

Photos already inside those bounds are re-encoded but not scaled, and the
original capture is deleted as soon as the compressed copy is written.

### Front-camera mirroring

The platform mirrors a front-camera preview, but `takePicture()` writes the
true frame, so the two disagree. Each selfie step resolves that on the side
that keeps the result usable:

- **Selfie** — the preview stays mirrored and the stored photo is flipped to
  match it, the same way `liveness_sdk` mirrors its clip.
- **Selfie with KTP** — the preview is un-mirrored (`mirrorPreview: false`) and
  the photo is stored as shot, so the card's printed text stays readable.

## KTP OCR

Steps 5 and 6 are powered by `packages/ktp_scanner`, the same self-contained
module used by the `ktp-ocr-scanner` project. It provides the full-screen card
camera, runs Google ML Kit Text Recognition on an orientation-corrected crop of
the guide frame, parses the printed labels into `KtpFieldKey` values and crops
the holder's portrait off the card with face detection.

```dart
final capture = await Navigator.of(context).push<KtpCapture>(
  MaterialPageRoute(builder: (_) => const KtpCameraPage()),
);
final result = await KtpScanner().scanCapture(capture!);
// result.data holds the parsed fields, result.portraitPath the cropped photo.
```

The demo hands `result.data` to `EKycController.setKtpScan`, which seeds the
editable record shown on step 6. See
[packages/ktp_scanner/README.md](packages/ktp_scanner/README.md) for the full
reference.

## Liveness detection

Step 2 is powered by `packages/liveness_sdk`, a self-contained module bundled in
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

## Project layout

```
lib/
  main.dart            app entry point, theme and EKycScope wiring
  screens/             the seven step screens plus the success screen
  models/              in-memory draft: consent, KTP details, media assets
  state/               EKycController (ChangeNotifier) and EKycScope
  camera/              shared full-screen capture page (card / face / face+card)
  widgets/             step scaffold, form fields, guidelines, video player
  theme/               brand palette, Material theme, liveness config
  utils/               formatting, masking and validation helpers
packages/
  liveness_sdk/        reusable face liveness module (see its own README)
  ktp_scanner/         reusable KTP capture + OCR module (see its own README)
android/ ios/          platform projects
assets/icon/           app icon / brand palette source
```

State lives in a single `EKycController` (`ChangeNotifier`) exposed to the widget
tree through `EKycScope`, an `InheritedNotifier`. Rescanning the card replaces
the stored fields and clears the confirmation, so the user always re-checks the
OCR output before submitting.

## Key dependencies

| Package                          | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `camera`                         | Selfie, card and liveness capture               |
| `google_mlkit_face_detection`    | On-device face landmarks, and the card portrait |
| `google_mlkit_text_recognition`  | On-device OCR of the KTP                        |
| `image`                          | Orientation baking and portrait cropping        |
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
