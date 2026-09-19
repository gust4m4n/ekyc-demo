import 'dart:math';

import 'package:flutter/widgets.dart';

import '../config/country_profile.dart';
import '../config/country_profiles.dart';
import '../models/ekyc_draft.dart';

/// Holds the in-memory eKYC draft for the current session.
class EKycController extends ChangeNotifier {
  CountryProfile _country = kDefaultCountryProfile;
  ConsentData? _consent;
  IdentityData? _identity;
  AddressData? _address;
  MediaAsset? _documentFront;
  MediaAsset? _documentBack;
  MediaAsset? _selfiePhoto;
  MediaAsset? _livenessVideo;

  /// Market the whole flow is configured for.
  CountryProfile get country => _country;

  ConsentData? get consent => _consent;
  IdentityData? get identity => _identity;
  AddressData? get address => _address;
  MediaAsset? get documentFront => _documentFront;
  MediaAsset? get documentBack => _documentBack;
  MediaAsset? get selfiePhoto => _selfiePhoto;
  MediaAsset? get livenessVideo => _livenessVideo;

  /// Document the user said they would present; drives the capture frame.
  DocumentType get documentType =>
      _identity?.documentType ?? _country.defaultDocument;

  bool get hasConsent => _consent?.accepted ?? false;
  bool get hasIdentity => _identity != null;
  bool get hasAddress => _address != null;

  /// The back side stays optional: not every document carries data on it.
  bool get hasMedia =>
      _documentFront != null && _selfiePhoto != null && _livenessVideo != null;

  bool get isReadyToSubmit =>
      hasConsent && hasIdentity && hasAddress && hasMedia;

  /// Switching market invalidates identity and address, which were validated
  /// against the previous country's rules.
  void setCountry(CountryProfile value) {
    if (_country.code == value.code) return;
    _country = value;
    _identity = null;
    _address = null;
    notifyListeners();
  }

  void acceptConsent() {
    _consent = ConsentData(accepted: true, acceptedAt: DateTime.now());
    notifyListeners();
  }

  void setIdentity(IdentityData value) {
    _identity = value;
    notifyListeners();
  }

  void setAddress(AddressData value) {
    _address = value;
    notifyListeners();
  }

  void setDocumentFront(MediaAsset value) {
    _replaceFile(_documentFront, value);
    _documentFront = value;
    notifyListeners();
  }

  void setDocumentBack(MediaAsset? value) {
    if (value == null) {
      _deleteFile(_documentBack);
      _documentBack = null;
    } else {
      _replaceFile(_documentBack, value);
      _documentBack = value;
    }
    notifyListeners();
  }

  void setSelfiePhoto(MediaAsset value) {
    _replaceFile(_selfiePhoto, value);
    _selfiePhoto = value;
    notifyListeners();
  }

  void setLivenessVideo(MediaAsset value) {
    _replaceFile(_livenessVideo, value);
    _livenessVideo = value;
    notifyListeners();
  }

  /// Drops the draft and removes the captured media from disk.
  void clear() {
    for (final asset in _assets) {
      _deleteFile(asset);
    }
    _consent = null;
    _identity = null;
    _address = null;
    _documentFront = null;
    _documentBack = null;
    _selfiePhoto = null;
    _livenessVideo = null;
    notifyListeners();
  }

  /// Random reference shown by the simulated submission screen.
  String buildDemoReference() {
    final random = Random();
    final digits = List<int>.generate(8, (_) => random.nextInt(10)).join();
    return 'DEMO-$digits';
  }

  List<MediaAsset?> get _assets => [
    _documentFront,
    _documentBack,
    _selfiePhoto,
    _livenessVideo,
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
