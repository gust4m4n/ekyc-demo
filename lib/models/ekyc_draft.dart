import 'dart:io';

import 'package:ktp_scanner/ktp_scanner.dart';

/// Session-scoped draft of everything the user captured.
///
/// Nothing here is persisted to disk or sent anywhere: the demo keeps it in
/// memory only.
class ConsentData {
  const ConsentData({required this.accepted, required this.acceptedAt});

  final bool accepted;
  final DateTime acceptedAt;
}

/// Width divided by height of a KTP (ID-1, ISO/IEC 7810).
const double kKtpAspectRatio = 1.586;

/// The KTP fields as they stand after OCR plus any correction the user made.
///
/// The demo collects no identity data beyond what is printed on the card, so
/// this is the whole KYC record.
class KtpDetails {
  const KtpDetails(this.values);

  const KtpDetails.empty() : values = const {};

  /// Seeds the record from a scan; unreadable fields are simply absent.
  factory KtpDetails.fromScan(KtpData data) {
    return KtpDetails({
      for (final field in data.fields)
        if (field.value.trim().isNotEmpty) field.key: field.value.trim(),
    });
  }

  final Map<KtpFieldKey, String> values;

  String? operator [](KtpFieldKey key) {
    final value = values[key]?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  bool get isEmpty => values.values.every((value) => value.trim().isEmpty);

  /// Fields that carry a value, in the order they are printed on the card.
  List<KtpField> get filled => [
    for (final key in KtpFieldKey.values)
      if (this[key] != null) KtpField(key, this[key]!),
  ];

  KtpDetails withValues(Map<KtpFieldKey, String> edits) {
    return KtpDetails({
      for (final entry in edits.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    });
  }
}

/// A captured photo or recorded clip kept for the duration of the session.
class MediaAsset {
  const MediaAsset({
    required this.uri,
    required this.mimeType,
    required this.sizeBytes,
    this.durationSeconds,
  });

  final String uri;
  final String mimeType;
  final int sizeBytes;

  /// Only set for the liveness clip.
  final double? durationSeconds;

  File get file => File(uri);

  String get readableSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).round()} KB';
  }
}
