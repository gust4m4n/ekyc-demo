import 'dart:math' as math;
import 'dart:ui';

import '../models/ktp_data.dart';
import 'ocr_line.dart';
import 'value_rules.dart';

/// What [parseKtp] could make of the recognized lines.
typedef KtpParseOutcome = ({bool recognized, KtpData data});

/// Reads a KTP from the lines returned by OCR.
///
/// The card prints a label column and a value column, and ML Kit returns them
/// either merged into one line or split across two. Every value is therefore
/// resolved by position: inline after the label, then the nearest line to the
/// right on the same row, then the line directly below.
KtpParseOutcome parseKtp({required List<OcrLine> lines}) {
  final cleaned =
      <OcrLine>[
        for (final line in lines)
          if (line.text.trim().isNotEmpty)
            OcrLine(
              text: line.text.trim().replaceAll(RegExp(r'\s+'), ' '),
              box: line.box,
            ),
      ]..sort((a, b) {
        final row = a.box.top.compareTo(b.box.top);
        return row != 0 ? row : a.box.left.compareTo(b.box.left);
      });

  final recognized = looksLikeKtp([for (final l in cleaned) l.text]);
  return (recognized: recognized, data: _readKtp(_Layout(cleaned)));
}

/// True when enough KTP keywords are present to treat the image as a KTP.
bool looksLikeKtp(List<String> lines) {
  final haystack = _normalize(lines.join(' '));

  var score = 0;
  for (final keyword in const [
    'nik',
    'provinsi',
    'tempattgllahir',
    'goldarah',
    'golongandarah',
    'statusperkawinan',
    'kewarganegaraan',
    'berlakuhingga',
    'kecamatan',
    'keldesa',
    'rtrw',
  ]) {
    if (haystack.contains(keyword)) score++;
  }
  return score > 0;
}

// --- field reader ----------------------------------------------------------

KtpData _readKtp(_Layout layout) {
  final fields = <KtpField>[];

  void add(KtpFieldKey key, String? value) {
    final cleaned = _clean(value ?? '');
    if (cleaned.isNotEmpty) fields.add(KtpField(key, cleaned));
  }

  final provinsiLine = layout.labelLineOf('provinsi');
  add(KtpFieldKey.provinsi, layout.read('provinsi'));

  // Some cards print only the regency name, without the KOTA / KABUPATEN word.
  final regency =
      layout.readLine('kabupaten') ??
      (provinsiLine == null ? null : layout.takeBelow(provinsiLine));
  add(KtpFieldKey.kabupatenKota, regency);

  final nik = normalizeNik(layout.read('nik') ?? '') ?? layout.findNik();
  add(KtpFieldKey.nik, nik);

  add(KtpFieldKey.nama, layout.read('nama'));

  final birth = layout.read('ttl');
  if (birth != null) {
    final date = kLooseDatePattern.firstMatch(birth);
    if (date == null) {
      add(KtpFieldKey.tempatLahir, birth);
    } else {
      add(
        KtpFieldKey.tempatLahir,
        birth.substring(0, date.start).replaceAll(',', ''),
      );
      add(KtpFieldKey.tanggalLahir, normalizeDate(birth));
    }
  }

  // Gender and blood type share one printed row.
  var gender = layout.read('kelamin');
  String? bloodType;
  if (gender != null) {
    final split = RegExp(
      r'gol\.?\s*darah',
      caseSensitive: false,
    ).firstMatch(gender);
    if (split != null) {
      bloodType = gender.substring(split.end);
      gender = gender.substring(0, split.start);
    }
  }
  bloodType ??= layout.read('darah');

  if (gender != null) {
    add(KtpFieldKey.jenisKelamin, snapTo(gender, kGenders) ?? gender);
  }
  if (bloodType != null) {
    add(KtpFieldKey.golonganDarah, normalizeBloodType(bloodType));
  }

  add(KtpFieldKey.alamat, layout.read('alamat'));

  final rtRw = layout.read('rtrw');
  if (rtRw != null) add(KtpFieldKey.rtRw, normalizeRtRw(rtRw) ?? rtRw);

  add(KtpFieldKey.kelurahanDesa, layout.read('keldesa'));
  add(KtpFieldKey.kecamatan, layout.read('kecamatan'));

  final religion = layout.read('agama');
  if (religion != null) {
    add(KtpFieldKey.agama, snapTo(religion, kReligions) ?? religion);
  }

  final marital = layout.read('kawin');
  if (marital != null) {
    add(
      KtpFieldKey.statusPerkawinan,
      snapTo(marital, kMaritalStatuses) ?? marital,
    );
  }

  add(KtpFieldKey.pekerjaan, layout.read('pekerjaan'));

  final citizenship = layout.read('warga');
  if (citizenship != null) {
    add(
      KtpFieldKey.kewarganegaraan,
      snapTo(citizenship, kCitizenships) ?? citizenship,
    );
  }

  final validity = layout.read('berlaku');
  if (validity != null) {
    add(
      KtpFieldKey.berlakuHingga,
      snapTo(validity, const ['SEUMUR HIDUP']) ??
          normalizeDate(validity) ??
          validity,
    );
  }

  // Place and date of issue sit unlabelled under the portrait.
  final issued = layout.findIssuance();
  add(KtpFieldKey.tempatDikeluarkan, issued?.place);
  add(KtpFieldKey.tanggalDikeluarkan, issued?.date);

  // Labels have to be read top-down because the layout consumes lines as it
  // goes; sorting afterwards restores the intended display order.
  fields.sort((a, b) => a.key.index.compareTo(b.key.index));

  return KtpData(fields);
}

// --- layout reader ---------------------------------------------------------

class _FieldSpec {
  const _FieldSpec(this.key, this.aliases);

  final String key;

  /// Normalized label spellings, longest first.
  final List<String> aliases;
}

const List<_FieldSpec> _ktpSpecs = [
  _FieldSpec('provinsi', ['provinsi']),
  _FieldSpec('kabupaten', ['kabupaten', 'kotamadya', 'kota']),
  _FieldSpec('nik', ['nik']),
  _FieldSpec('nama', ['nama']),
  _FieldSpec('ttl', [
    'tempattanggallahir',
    'tempattgllahir',
    'tempatlahir',
    'tempattgi',
  ]),
  _FieldSpec('kelamin', ['jeniskelamin']),
  _FieldSpec('darah', ['golongandarah', 'goldarah']),
  _FieldSpec('alamat', ['alamat']),
  _FieldSpec('rtrw', ['rtrw']),
  _FieldSpec('keldesa', ['kelurahandesa', 'keldesa', 'kelurahan']),
  _FieldSpec('kecamatan', ['kecamatan']),
  _FieldSpec('agama', ['agama']),
  _FieldSpec('kawin', ['statusperkawinan']),
  _FieldSpec('pekerjaan', ['pekerjaan']),
  _FieldSpec('warga', ['kewarganegaraan']),
  _FieldSpec('berlaku', ['berlakuhingga', 'berlaku']),
];

class _LabelHit {
  const _LabelHit(this.key, this.length, this.distance);

  final String key;

  /// Number of normalized characters the label occupies.
  final int length;
  final int distance;
}

class _Layout {
  _Layout(this.lines) {
    for (final line in lines) {
      final hit = _matchLabel(line.text);
      if (hit != null) _labels[line] = hit;
    }
  }

  final List<OcrLine> lines;
  final Map<OcrLine, _LabelHit> _labels = {};
  final Set<OcrLine> _consumed = {};

  OcrLine? labelLineOf(String key) {
    for (final line in lines) {
      if (_labels[line]?.key == key) return line;
    }
    return null;
  }

  /// Value printed for [key], resolved inline, to the right, or below.
  String? read(String key) {
    for (final line in lines) {
      final hit = _labels[line];
      if (hit == null || hit.key != key || _consumed.contains(line)) continue;

      final value = _valueFor(line, hit);
      if (value != null && value.isNotEmpty) {
        _consumed.add(line);
        return value;
      }
    }
    return null;
  }

  /// Whole line carrying [key], used for headers such as `KABUPATEN BATUBARA`.
  String? readLine(String key) {
    for (final line in lines) {
      if (_labels[line]?.key != key || _consumed.contains(line)) continue;
      _consumed.add(line);
      return line.text;
    }
    return null;
  }

  /// First unconsumed, unlabelled line sitting under [anchor].
  String? takeBelow(OcrLine anchor) {
    final candidate = _below(anchor);
    if (candidate == null) return null;
    _consumed.add(candidate);
    return candidate.text;
  }

  /// 16 digit run anywhere on the card, used when the NIK label is unreadable.
  String? findNik() {
    for (final line in lines) {
      final match = _nikLikePattern.firstMatch(line.text.replaceAll(' ', ''));
      if (match == null) continue;
      final digits = digitsOf(match.group(0)!);
      if (digits.length >= 16) return digits.substring(0, 16);
    }
    return null;
  }

  /// The unlabelled place and date of issue printed under the portrait.
  ({String? place, String? date})? findIssuance() {
    final bounds = _bounds();
    if (bounds == null) return null;

    final region = Rect.fromLTRB(
      bounds.left + bounds.width * 0.45,
      bounds.top + bounds.height * 0.55,
      bounds.right,
      bounds.bottom,
    );

    OcrLine? dateLine;
    for (final line in lines) {
      if (!_isFree(line) || !region.contains(line.box.center)) continue;
      if (_letters.hasMatch(line.text)) continue;
      if (normalizeDate(line.text) == null) continue;
      dateLine = line;
    }
    if (dateLine == null) return null;
    _consumed.add(dateLine);

    OcrLine? placeLine;
    for (final line in lines) {
      if (!_isFree(line) || !region.contains(line.box.center)) continue;
      if (line.box.bottom > dateLine.box.top + dateLine.box.height * 0.5) {
        continue;
      }
      if (dateLine.box.top - line.box.bottom > dateLine.box.height * 2) {
        continue;
      }
      if (_horizontalOverlap(line.box, dateLine.box) < 0.3) continue;
      if (!_placeOnly.hasMatch(line.text)) continue;
      placeLine = line;
    }
    if (placeLine != null) _consumed.add(placeLine);

    return (place: placeLine?.text, date: normalizeDate(dateLine.text));
  }

  bool _isFree(OcrLine line) =>
      !_consumed.contains(line) && !_labels.containsKey(line);

  String? _valueFor(OcrLine label, _LabelHit hit) {
    final colon = label.text.indexOf(_colon);
    final inline = _clean(
      colon >= 0
          ? label.text.substring(colon + 1)
          : _stripNormalizedPrefix(label.text, hit.length),
    );
    if (inline.isNotEmpty) return inline;

    final neighbour = _rightOf(label) ?? _below(label);
    if (neighbour == null) return null;

    _consumed.add(neighbour);
    return _clean(neighbour.text);
  }

  /// Nearest usable line on the same row, skipping stray colon columns.
  OcrLine? _rightOf(OcrLine label) {
    final candidates =
        lines
            .where(
              (line) =>
                  !identical(line, label) &&
                  !_consumed.contains(line) &&
                  line.box.left >= label.box.left + label.box.width * 0.5 &&
                  _verticalOverlap(label.box, line.box) >= 0.35,
            )
            .toList()
          ..sort((a, b) => a.box.left.compareTo(b.box.left));

    for (final candidate in candidates) {
      if (_labels.containsKey(candidate)) return null;
      if (_clean(candidate.text).isEmpty) {
        _consumed.add(candidate);
        continue;
      }
      return candidate;
    }
    return null;
  }

  OcrLine? _below(OcrLine label) {
    OcrLine? best;
    for (final line in lines) {
      if (identical(line, label) || !_isFree(line)) continue;
      if (line.box.top < label.box.bottom - label.box.height * 0.3) continue;
      if (line.box.top - label.box.bottom > label.box.height * 1.5) continue;
      if (_horizontalOverlap(label.box, line.box) < 0.3) continue;
      if (_clean(line.text).isEmpty) continue;
      if (best == null || line.box.top < best.box.top) best = line;
    }
    return best;
  }

  Rect? _bounds() {
    if (lines.isEmpty) return null;
    var bounds = lines.first.box;
    for (final line in lines.skip(1)) {
      bounds = bounds.expandToInclude(line.box);
    }
    return bounds;
  }
}

/// Best label match for [text], tolerating a few OCR typos.
_LabelHit? _matchLabel(String text) {
  final normalized = _normalize(text);
  if (normalized.isEmpty) return null;

  _LabelHit? best;
  for (final spec in _ktpSpecs) {
    for (final alias in spec.aliases) {
      if (normalized.length < alias.length) continue;
      final prefix = normalized.substring(0, alias.length);

      final distance = _prefixDistance(prefix, alias);
      // Fuzzy matching short labels produces too many false positives.
      final tolerance = alias.length < 5
          ? 0
          : alias.length <= 8
          ? 1
          : 2;
      if (distance > tolerance) continue;

      if (best == null ||
          distance < best.distance ||
          (distance == best.distance && alias.length > best.length)) {
        best = _LabelHit(spec.key, alias.length, distance);
      }
    }
  }
  return best;
}

int _prefixDistance(String prefix, String alias) {
  var distance = 0;
  for (var i = 0; i < alias.length; i++) {
    if (prefix[i] != alias[i]) distance++;
  }
  return distance;
}

/// Drops the first [normalizedLength] alphanumeric characters from [raw].
String _stripNormalizedPrefix(String raw, int normalizedLength) {
  var seen = 0;
  for (var i = 0; i < raw.length; i++) {
    if (_alphanumeric.hasMatch(raw[i])) seen++;
    if (seen == normalizedLength) return raw.substring(i + 1);
  }
  return '';
}

double _verticalOverlap(Rect a, Rect b) {
  final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  final shortest = math.min(a.height, b.height);
  return shortest <= 0 ? 0 : overlap / shortest;
}

double _horizontalOverlap(Rect a, Rect b) {
  final overlap = math.min(a.right, b.right) - math.max(a.left, b.left);
  final narrowest = math.min(a.width, b.width);
  return narrowest <= 0 ? 0 : overlap / narrowest;
}

String _clean(String value) => value
    .replaceAll(RegExp(r'^[\s:;.\-–—_]+'), '')
    .replaceAll(RegExp(r'[\s:;]+$'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

final RegExp _nikLikePattern = RegExp(r'[0-9OoDQIilL|ZzSsBbTtGgq]{16,}');
final RegExp _alphanumeric = RegExp('[a-zA-Z0-9]');
final RegExp _letters = RegExp('[A-Za-z]');
final RegExp _placeOnly = RegExp(r'^[A-Za-z][A-Za-z .]{2,29}$');
final RegExp _colon = RegExp('[:\uFF1A]');
