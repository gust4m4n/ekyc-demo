import 'dart:io';

/// Formatting, masking and validation helpers shared by the eKYC steps.
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

/// ------------------------------------------------------------- media helpers
/// Each validator returns `null` when the file is acceptable, or a message.
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
