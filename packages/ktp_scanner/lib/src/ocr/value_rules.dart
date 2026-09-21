import 'dart:math' as math;

/// Vocabularies and repair helpers for the noisy values OCR returns.

const List<String> kGenders = ['LAKI-LAKI', 'PEREMPUAN'];

const List<String> kReligions = [
  'ISLAM',
  'KRISTEN',
  'KATOLIK',
  'HINDU',
  'BUDHA',
  'KHONGHUCU',
  'KEPERCAYAAN',
];

const List<String> kMaritalStatuses = [
  'BELUM KAWIN',
  'KAWIN',
  'CERAI HIDUP',
  'CERAI MATI',
];

const List<String> kCitizenships = ['WNI', 'WNA'];

/// Day, month and year with any separator, tolerating OCR confusables.
final RegExp kLooseDatePattern = RegExp(
  r'[0-9OoDQIilL|ZzSsBbTtGgq]{1,2}\s*[-/.]\s*'
  r'[0-9OoDQIilL|ZzSsBbTtGgq]{1,2}\s*[-/.]\s*'
  r'[0-9OoDQIilL|ZzSsBbTtGgq]{4}',
);

/// Characters the OCR-B typeface on a KTP is commonly misread as.
const Map<String, String> _digitConfusables = {
  'O': '0',
  'o': '0',
  'D': '0',
  'Q': '0',
  'I': '1',
  'i': '1',
  'l': '1',
  'L': '1',
  '|': '1',
  'Z': '2',
  'z': '2',
  'S': '5',
  's': '5',
  'b': '6',
  'G': '6',
  'T': '7',
  't': '7',
  'B': '8',
  'g': '9',
  'q': '9',
};

/// Keeps only digits, repairing characters OCR confused with a digit.
String digitsOf(String value) {
  final buffer = StringBuffer();
  for (final char in value.split('')) {
    final repaired = _digitConfusables[char] ?? char;
    if (_digit.hasMatch(repaired)) buffer.write(repaired);
  }
  return buffer.toString();
}

/// Rewrites any date inside [value] as `dd-mm-yyyy`.
String? normalizeDate(String value) {
  final match = kLooseDatePattern.firstMatch(value);
  if (match == null) return null;

  final parts = match
      .group(0)!
      .split(RegExp(r'[-/.\s]+'))
      .where((part) => part.isNotEmpty)
      .map(digitsOf)
      .toList();
  if (parts.length != 3 || parts[2].length != 4) return null;

  return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
}

/// Rewrites an `RT/RW` pair as `ddd/ddd` when both halves are readable.
String? normalizeRtRw(String value) {
  final halves = value.split(RegExp(r'[/\\|]'));
  if (halves.length != 2) return null;

  final rt = digitsOf(halves[0]);
  final rw = digitsOf(halves[1]);
  if (rt.isEmpty || rw.isEmpty) return null;

  return '${rt.padLeft(3, '0')}/${rw.padLeft(3, '0')}';
}

/// Keeps the digits of a NIK as read, without enforcing a length.
String? normalizeNik(String value) {
  final digits = digitsOf(value);
  return digits.isEmpty ? null : digits;
}

/// `A`, `B`, `AB` or `O`, with the `0`/`O` confusion resolved.
String? normalizeBloodType(String value) {
  final compact = value
      .toUpperCase()
      .replaceAll('0', 'O')
      .replaceAll(RegExp(r'[^ABO+\-]'), '');
  final match = RegExp(r'^(AB|A|B|O)([+-])?$').firstMatch(compact);
  return match == null ? null : compact;
}

/// Snaps [value] to the closest entry of [options] when it is close enough.
String? snapTo(String value, List<String> options) {
  final needle = _compact(value);
  if (needle.isEmpty) return null;

  var best = options.first;
  var bestDistance = 1 << 30;
  for (final option in options) {
    final distance = _levenshtein(needle, _compact(option));
    if (distance < bestDistance) {
      bestDistance = distance;
      best = option;
    }
  }

  final tolerance = math.max(1, (_compact(best).length * 0.3).floor());
  return bestDistance <= tolerance ? best : null;
}

String _compact(String value) =>
    value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

final RegExp _digit = RegExp(r'\d');

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  final current = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final substitution = previous[j] + (a[i] == b[j] ? 0 : 1);
      current[j + 1] = math.min(
        math.min(current[j] + 1, previous[j + 1] + 1),
        substitution,
      );
    }
    previous = List<int>.of(current);
  }
  return previous[b.length];
}
