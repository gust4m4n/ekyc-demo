import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ktp_scanner/ktp_scanner.dart';

import '../models/ekyc_draft.dart';

/// Holds the in-memory eKYC draft for the current session.
///
/// Capture order: liveness video, selfie, selfie holding the KTP, then the
/// scanned KTP whose fields become the KYC record.
class EKycController extends ChangeNotifier {
  ConsentData? _consent;
  MediaAsset? _livenessVideo;
  MediaAsset? _selfiePhoto;
  MediaAsset? _selfieWithKtpPhoto;
  MediaAsset? _ktpPhoto;
  MediaAsset? _ktpPortrait;
  KtpDetails _ktpDetails = const KtpDetails.empty();
  bool _ktpConfirmed = false;

  ConsentData? get consent => _consent;
  MediaAsset? get livenessVideo => _livenessVideo;
  MediaAsset? get selfiePhoto => _selfiePhoto;
  MediaAsset? get selfieWithKtpPhoto => _selfieWithKtpPhoto;
  MediaAsset? get ktpPhoto => _ktpPhoto;

  /// Portrait cropped off the card by the scanner, when a face was found.
  MediaAsset? get ktpPortrait => _ktpPortrait;

  KtpDetails get ktpDetails => _ktpDetails;

  bool get hasConsent => _consent?.accepted ?? false;
  bool get hasLiveness => _livenessVideo != null;
  bool get hasSelfie => _selfiePhoto != null;
  bool get hasSelfieWithKtp => _selfieWithKtpPhoto != null;
  bool get hasKtpPhoto => _ktpPhoto != null;

  /// True once the user has reviewed the OCR output on the edit screen. The
  /// values themselves are taken as given: a worn card does not always read.
  bool get hasKtpDetails => _ktpConfirmed;

  bool get hasMedia =>
      hasLiveness && hasSelfie && hasSelfieWithKtp && hasKtpPhoto;

  bool get isReadyToSubmit => hasConsent && hasMedia && hasKtpDetails;

  void acceptConsent() {
    _consent = ConsentData(accepted: true, acceptedAt: DateTime.now());
    notifyListeners();
  }

  void setLivenessVideo(MediaAsset value) {
    _replaceFile(_livenessVideo, value);
    _livenessVideo = value;
    notifyListeners();
  }

  void setSelfiePhoto(MediaAsset value) {
    _replaceFile(_selfiePhoto, value);
    _selfiePhoto = value;
    notifyListeners();
  }

  void setSelfieWithKtpPhoto(MediaAsset value) {
    _replaceFile(_selfieWithKtpPhoto, value);
    _selfieWithKtpPhoto = value;
    notifyListeners();
  }

  /// Stores a scan: the orientation-corrected card image, the portrait cropped
  /// off it and the fields OCR read. The fields stay unconfirmed until the
  /// user reviews them on the next step.
  void setKtpScan({
    required MediaAsset photo,
    MediaAsset? portrait,
    required KtpData data,
  }) {
    _replaceFile(_ktpPhoto, photo);
    _ktpPhoto = photo;

    if (portrait == null) {
      _deleteFile(_ktpPortrait);
      _ktpPortrait = null;
    } else {
      _replaceFile(_ktpPortrait, portrait);
      _ktpPortrait = portrait;
    }

    _ktpDetails = KtpDetails.fromScan(data);
    _ktpConfirmed = false;
    notifyListeners();
  }

  /// Accepts the fields as shown on the edit screen, corrections included.
  void confirmKtpDetails(KtpDetails value) {
    _ktpDetails = value;
    _ktpConfirmed = true;
    notifyListeners();
  }

  /// Drops the draft and removes the captured media from disk.
  void clear() {
    for (final asset in _assets) {
      _deleteFile(asset);
    }
    _consent = null;
    _livenessVideo = null;
    _selfiePhoto = null;
    _selfieWithKtpPhoto = null;
    _ktpPhoto = null;
    _ktpPortrait = null;
    _ktpDetails = const KtpDetails.empty();
    _ktpConfirmed = false;
    notifyListeners();
  }

  /// Random reference shown by the simulated submission screen.
  String buildDemoReference() {
    final random = Random();
    final digits = List<int>.generate(8, (_) => random.nextInt(10)).join();
    return 'DEMO-$digits';
  }

  List<MediaAsset?> get _assets => [
    _livenessVideo,
    _selfiePhoto,
    _selfieWithKtpPhoto,
    _ktpPhoto,
    _ktpPortrait,
  ];

  void _replaceFile(MediaAsset? previous, MediaAsset next) {
    if (previous != null && previous.uri != next.uri) {
      _deleteFile(previous);
    }
  }

  void _deleteFile(MediaAsset? asset) {
    if (asset == null) return;
    try {
      final file = asset.file;
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Media cleanup is best effort; never surface the path in a log.
    }
  }

  @override
  void dispose() {
    for (final asset in _assets) {
      _deleteFile(asset);
    }
    super.dispose();
  }
}

/// Exposes the [EKycController] to the whole step flow.
class EKycScope extends InheritedNotifier<EKycController> {
  const EKycScope({
    super.key,
    required EKycController controller,
    required super.child,
  }) : super(notifier: controller);

  static EKycController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EKycScope>();
    assert(scope != null, 'EKycScope is missing above this widget.');
    return scope!.notifier!;
  }

  /// Reads the controller without subscribing to changes.
  static EKycController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<EKycScope>();
    assert(scope != null, 'EKycScope is missing above this widget.');
    return scope!.notifier!;
  }
}
