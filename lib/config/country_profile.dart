import 'package:flutter/foundation.dart';

/// Country-agnostic description of what a single market expects from an
/// applicant.
///
/// Every field, validation rule and label that used to be hard coded for one
/// country now comes from a [CountryProfile], so adding a market is a data
/// change rather than a code change.

/// Identity documents the demo knows how to capture.
enum DocumentType {
  nationalId,
  passport,
  drivingLicence,
  residencePermit;

  String get label => switch (this) {
    DocumentType.nationalId => 'National ID card',
    DocumentType.passport => 'Passport',
    DocumentType.drivingLicence => 'Driving licence',
    DocumentType.residencePermit => 'Residence permit',
  };

  /// Frame drawn over the camera preview.
  ///
  /// ID-1 cards are 1.586:1 (ISO/IEC 7810); a TD3 passport data page is
  /// roughly 1.42:1.
  double get aspectRatio => this == DocumentType.passport ? 1.42 : 1.586;

  /// Passports carry everything on the data page; cards do not.
  bool get hasBackSide => this != DocumentType.passport;

  String get frontLabel =>
      this == DocumentType.passport ? 'Data page' : 'Front side';

  String get captureHint => switch (this) {
    DocumentType.passport =>
      'Open the passport at the photo page and lay it flat inside the frame.',
    _ => 'Place the card on a flat surface and fill the frame with it.',
  };
}

/// A regex backed rule with the copy needed to explain a rejection.
@immutable
class PatternRule {
  const PatternRule({
    required this.pattern,
    required this.requirement,
    required this.example,
    this.maxLength,
    this.digitsOnly = false,
  });

  final String pattern;

  /// Human readable requirement, e.g. `exactly 16 digits`.
  final String requirement;

  /// Placeholder shown in the input.
  final String example;

  final int? maxLength;

  /// Restricts the keyboard and the input formatter to digits.
  final bool digitsOnly;

  bool matches(String value) => RegExp(pattern).hasMatch(value);
}

/// Fallbacks for documents that are not issued by a single country registry.
const PatternRule kPassportNumberRule = PatternRule(
  pattern: r'^[A-Z0-9]{6,9}$',
  requirement: '6–9 letters or digits',
  example: 'X1234567',
  maxLength: 9,
);

const PatternRule kDrivingLicenceNumberRule = PatternRule(
  pattern: r'^[A-Z0-9-]{5,20}$',
  requirement: '5–20 letters, digits or hyphens',
  example: 'D1234-5678-90',
  maxLength: 20,
);

const PatternRule kResidencePermitNumberRule = PatternRule(
  pattern: r'^[A-Z0-9-]{5,20}$',
  requirement: '5–20 letters, digits or hyphens',
  example: 'RP1234567',
  maxLength: 20,
);

@immutable
class CountryProfile {
  const CountryProfile({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.minimumAge,
    required this.acceptedDocuments,
    required this.localityLabel,
    this.nationalIdLabel = 'National ID number',
    this.nationalIdRule,
    this.nationalIdHasExpiry = true,
    this.administrativeAreaLabel,
    this.administrativeAreas = const <String>[],
    this.administrativeAreaRequired = true,
    this.postalCodeLabel = 'Postal code',
    this.postalCodeRule,
    this.addressExample = '12 Main Street, Apt 3',
  });

  /// ISO 3166-1 alpha-2, e.g. `ID`, `SG`, `GB`.
  final String code;
  final String name;

  /// ITU-T E.164 country calling code, prefilled in the phone field.
  final String dialCode;

  /// Legal age to open an account without a guardian.
  final int minimumAge;

  final List<DocumentType> acceptedDocuments;

  /// What a national ID is called locally, e.g. `NRIC number`.
  final String nationalIdLabel;

  /// Absent when the country issues no national ID card.
  final PatternRule? nationalIdRule;

  /// A handful of national IDs never expire.
  final bool nationalIdHasExpiry;

  /// City, town or municipality.
  final String localityLabel;

  /// `State`, `Province`, `Emirate`, … or null when the country has no such
  /// level in a postal address.
  final String? administrativeAreaLabel;

  /// When empty the administrative area is entered as free text.
  final List<String> administrativeAreas;

  /// False where the level exists but carriers do not rely on it, such as a
  /// UK county.
  final bool administrativeAreaRequired;

  final String postalCodeLabel;

  /// Absent for countries without postal codes (the field is then hidden).
  final PatternRule? postalCodeRule;

  final String addressExample;

  bool get hasAdministrativeArea => administrativeAreaLabel != null;

  bool get hasPostalCode => postalCodeRule != null;

  bool get supportsNationalId =>
      acceptedDocuments.contains(DocumentType.nationalId) &&
      nationalIdRule != null;

  DocumentType get defaultDocument => acceptedDocuments.first;

  String documentNumberLabel(DocumentType type) => switch (type) {
    DocumentType.nationalId => nationalIdLabel,
    DocumentType.passport => 'Passport number',
    DocumentType.drivingLicence => 'Licence number',
    DocumentType.residencePermit => 'Permit number',
  };

  PatternRule documentNumberRule(DocumentType type) => switch (type) {
    DocumentType.nationalId => nationalIdRule ?? kPassportNumberRule,
    DocumentType.passport => kPassportNumberRule,
    DocumentType.drivingLicence => kDrivingLicenceNumberRule,
    DocumentType.residencePermit => kResidencePermitNumberRule,
  };

  /// Whether an expiry date must be collected for [type].
  bool documentExpires(DocumentType type) =>
      type == DocumentType.nationalId ? nationalIdHasExpiry : true;
}
