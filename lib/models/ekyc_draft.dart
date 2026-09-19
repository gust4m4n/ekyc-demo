import 'dart:io';

import '../config/country_profile.dart';

/// Session-scoped draft of everything the user entered.
///
/// Nothing here is persisted to disk or sent anywhere: the demo keeps it in
/// memory only.
class ConsentData {
  const ConsentData({required this.accepted, required this.acceptedAt});

  final bool accepted;
  final DateTime acceptedAt;
}

class IdentityData {
  const IdentityData({
    required this.documentType,
    required this.documentNumber,
    required this.issuingCountry,
    required this.givenNames,
    required this.familyName,
    required this.birthDate,
    required this.birthPlace,
    required this.nationality,
    required this.occupation,
    this.documentExpiry,
  });

  final DocumentType documentType;
  final String documentNumber;

  /// ISO 3166-1 alpha-2 code of the authority that issued the document.
  final String issuingCountry;

  final String givenNames;
  final String familyName;
  final DateTime birthDate;
  final String birthPlace;
  final String nationality;
  final String occupation;

  /// Null for documents that never expire, such as most national ID cards.
  final DateTime? documentExpiry;

  String get fullName => '$givenNames $familyName';
}

/// A postal address entered as one free text line plus the three
/// administrative levels picked from the dependent dropdowns.
class AddressData {
  const AddressData({
    required this.street,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.countryCode,
  });

  final String street;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final String countryCode;

  /// Single line rendering used by the review screen.
  String format(String countryName) {
    return [
      street,
      district,
      city,
      province,
      postalCode,
      countryName,
    ].where((part) => part.trim().isNotEmpty).join(', ');
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
