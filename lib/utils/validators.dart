import 'dart:io';

import '../config/country_profile.dart';

/// Formatting, masking and validation helpers shared by the eKYC steps.
///
/// Nothing in here assumes a particular country: every country-specific rule
/// arrives as a [PatternRule] or a plain parameter from the active
/// [CountryProfile].
const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `12 March 1998` — unambiguous in every English speaking market.
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatDate(value)}, $hour:$minute ${formatUtcOffset(value)}';
}

/// `UTC+07:00`, so a timestamp stays readable outside the device's own zone.
String formatUtcOffset(DateTime value) {
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = offset.inMinutes
      .abs()
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// `32••••••••1234` — keeps just enough for the user to recognise the value.
String maskDocumentNumber(String value) {
  if (value.length < 6) return '•' * value.length;
  final tailLength = value.length >= 10 ? 4 : 2;
  final headLength = value.length >= 10 ? 2 : 1;
  final head = value.substring(0, headLength);
  final tail = value.substring(value.length - tailLength);
  return '$head${'•' * (value.length - headLength - tailLength)}$tail';
}

int calculateAge(DateTime birthDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var age = today.year - birthDate.year;
  final hadBirthday =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) age -= 1;
  return age;
}

/// ---------------------------------------------------------------- validators
/// Each returns `null` when the value is acceptable, or an English message.

String? validateDocumentNumber(String? value, PatternRule rule, String label) {
  final input = (value ?? '').trim().toUpperCase();
  if (input.isEmpty) return '$label is required.';
  if (!rule.matches(input)) {
    return '$label must be ${rule.requirement}.';
  }
  return null;
}

/// Accepts every script, plus the separators that appear in legal names
/// (spaces, hyphens, apostrophes, periods). The old ASCII-only rule rejected
/// names such as `Müller`, `O'Brien-Ng` or `José`.
final RegExp _nameExpression = RegExp(
  r"^[\p{L}\p{M}][\p{L}\p{M} .'\u2019-]*$",
  unicode: true,
);

String? validateName(String? value, String label, {int min = 1, int max = 70}) {
  final input = (value ?? '').trim();
  if (input.isEmpty) return '$label is required.';
  if (input.length < min || input.length > max) {
    return '$label must be $min–$max characters.';
  }
  if (!_nameExpression.hasMatch(input)) {
    return '$label may only contain letters, spaces, hyphens, apostrophes '
        'and periods.';
  }
  return null;
}

String? validateLength(
  String? value,
  String label, {
  required int min,
  required int max,
}) {
  final input = (value ?? '').trim();
  if (input.isEmpty) return '$label is required.';
  if (input.length < min || input.length > max) {
    return '$label must be $min–$max characters.';
  }
  return null;
}

String? validateBirthDate(DateTime? value, {required int minimumAge}) {
  if (value == null) return 'Date of birth is required.';
  if (value.isAfter(DateTime.now())) {
    return 'Date of birth cannot be in the future.';
  }
  if (calculateAge(value) < minimumAge) {
    return 'You must be at least $minimumAge years old to continue.';
  }
  return null;
}

String? validateExpiryDate(DateTime? value, {required bool required}) {
  if (value == null) return required ? 'Expiry date is required.' : null;
  if (!value.isAfter(DateTime.now())) {
    return 'This document has expired. Use a valid document.';
  }
  return null;
}

/// Skipped entirely when the country has no postal code system.
String? validatePostalCode(String? value, PatternRule? rule, String label) {
  if (rule == null) return null;
  final input = (value ?? '').trim().toUpperCase();
  if (input.isEmpty) return '$label is required.';
  if (!rule.matches(input)) return '$label must be ${rule.requirement}.';
  return null;
}

String? validateRequiredChoice(Object? value, String label) {
  if (value == null || (value is String && value.isEmpty)) {
    return 'Select a $label.';
  }
  return null;
}

/// One named rule in an ordered list, so a screen can surface the first
/// failure only instead of every message at once.
class FieldCheck {
  const FieldCheck(this.field, this.run);

  final String field;
  final String? Function() run;
}

/// ------------------------------------------------------------- media helpers
const int kMaxPhotoBytes = 10 * 1024 * 1024;
const int kMaxVideoBytes = 25 * 1024 * 1024;
const int kMinPhotoLongEdge = 1280;
const Duration kMinVideoDuration = Duration(seconds: 5);
const Duration kMaxVideoDuration = Duration(seconds: 15);

const Map<String, String> _photoMimeTypes = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.heic': 'image/heic',
  '.heif': 'image/heic',
};

const Map<String, String> _videoMimeTypes = {
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
};

String _extensionOf(String path) {
  final index = path.lastIndexOf('.');
  if (index < 0) return '';
  return path.substring(index).toLowerCase();
}

String? photoMimeTypeOf(String path) => _photoMimeTypes[_extensionOf(path)];

String? videoMimeTypeOf(String path) => _videoMimeTypes[_extensionOf(path)];

/// Rejects a captured photo with a specific reason.
String? validatePhotoFile(File file, {required int longestEdge}) {
  if (!file.existsSync()) return 'The photo file could not be found.';
  if (photoMimeTypeOf(file.path) == null) {
    return 'Unsupported format. Use JPG, PNG or HEIC.';
  }
  if (file.lengthSync() > kMaxPhotoBytes) {
    return 'The photo is larger than 10 MB. Retake it at a lower resolution.';
  }
  if (longestEdge > 0 && longestEdge < kMinPhotoLongEdge) {
    return 'Resolution is too low (the longest edge must be at least '
        '$kMinPhotoLongEdge px).';
  }
  return null;
}

String? validateVideoFile(File file, {required Duration duration}) {
  if (!file.existsSync()) return 'The video file could not be found.';
  if (videoMimeTypeOf(file.path) == null) {
    return 'Unsupported format. Use MP4 or MOV.';
  }
  if (file.lengthSync() > kMaxVideoBytes) {
    return 'The video is larger than 25 MB. Record a shorter clip.';
  }
  if (duration < kMinVideoDuration) {
    return 'The video is too short (5 seconds minimum). Please record again.';
  }
  if (duration > kMaxVideoDuration) {
    return 'The video is too long (15 seconds maximum). Please record again.';
  }
  return null;
}
