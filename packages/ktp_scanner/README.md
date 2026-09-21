# ktp_scanner

Reusable, on-device scanner for the Indonesian **KTP**. It captures the card,
crops the photo down to the on-screen guide frame, extracts the printed fields
with ML Kit OCR and crops the holder's portrait photo off the card. Nothing
leaves the device.

## Install

Add the package by path (or by git URL) in the host app's `pubspec.yaml`:

```yaml
dependencies:
  ktp_scanner:
    path: packages/ktp_scanner
```

### Platform setup

**Android** — `minSdkVersion 24` and core library desugaring enabled in
`android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig { minSdk = 24 }
    compileOptions { isCoreLibraryDesugaringEnabled = true }
    dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
}
```

Camera permission in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** — deployment target 15.5+ and an `NSCameraUsageDescription` entry in
`Info.plist`.

## Use

### 1. The whole flow

```dart
final result = await KtpScannerPage.open(context);
if (result != null) {
  print(result.data.nik);
  print(result.portraitPath); // cropped photo of the holder
  result.dispose();           // removes the temporary files
}
```

`KtpScannerPage` can also be embedded as a `home:` or with an `onConfirm`
callback instead of popping a route.

### 2. Engine only, with your own UI

`KtpCameraPage` pops a `KtpCapture`: the photo plus the guide frame the user
lined the card up with. Hand it to `scanCapture` and the card is cut out of the
photo before anything is recognized.

```dart
final scanner = KtpScanner();

final capture = await Navigator.of(context).push<KtpCapture>(
  MaterialPageRoute(builder: (_) => const KtpCameraPage()),
);

final result = await scanner.scanCapture(capture!);
await scanner.dispose();
```

For a photo from elsewhere — a gallery pick, say — use `scan(File)` and
optionally pass your own `guide` rect in 0..1 fractions.

Render it with the bundled `KtpResultView`, or build your own from
`result.data`.

### 3. Parser only

```dart
final data = KtpScanner.parseLines([
  OcrLine(text: 'NIK : 3175070101909999', box: Rect.fromLTWH(10, 40, 300, 20)),
  // ...
]);
```

## Result

`KtpScanResult` exposes:

| Member         | Meaning                                                  |
| -------------- | -------------------------------------------------------- |
| `recognized`   | Whether the image looks like a KTP                       |
| `data`         | Typed fields — `nik`, `nama`, `tempatLahir`, `alamat`, … |
| `data.fields`  | The same values as an ordered, displayable list          |
| `data.toMap()` | Enum-name keyed map, ready for JSON                      |
| `imagePath`    | The card, upright and cropped to the guide frame         |
| `portraitPath` | Cropped photo of the holder, `null` if no face was found |
| `rawText`      | Everything OCR read                                      |

Both files live in the temp directory; call `result.dispose()` once you have
copied what you need.

Field labels (`Provinsi`, `NIK`, `Tempat Lahir`, …) stay in Indonesian because
they name what is printed on the card; every other string is English.

## How the card is cropped

The preview is painted with `BoxFit.cover`, so the guide frame is un-projected
back onto the sensor to get its position as 0..1 fractions of the still. That
rectangle — plus a small outward margin, so a slightly tighter still never
shaves off the card edges — is applied in the same decode pass that bakes the
EXIF rotation. OCR and face detection therefore only ever see the card.

## How the portrait is extracted

The capture is decoded once and its EXIF rotation is baked in, so OCR boxes and
pixel coordinates share one space. ML Kit face detection then finds the only
face on the card and the box is expanded into a 3:4 head-and-shoulders frame,
clamped to the image bounds, and cropped in a background isolate.
