import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ktp_scanner/ktp_scanner.dart';

/// Builds a line positioned like a real card row.
OcrLine line(
  String text, {
  required int row,
  double left = 10,
  double width = 300,
}) => OcrLine(text: text, box: Rect.fromLTWH(left, 40 + row * 30, width, 20));

Map<String, String> valuesOf(KtpData data) => {
  for (final field in data.fields) field.label: field.value,
};

KtpParseOutcome parse(List<OcrLine> lines) => parseKtp(lines: lines);

void main() {
  group('KTP', () {
    test('reads a card whose label and value share one line', () {
      final outcome = parse([
        line('PROVINSI SUMATERA UTARA', row: 0, left: 120, width: 260),
        line('KABUPATEN BATUBARA', row: 1, left: 140, width: 220),
        line('NIK : 3674072257025008', row: 2),
        line('Nama : SYAIFUL ARIF', row: 3),
        line('Tempat/Tgl Lahir : JAKARTA, 22-04-1984', row: 4),
        line('Jenis Kelamin : LAKI-LAKI', row: 5),
        line('Alamat : TAMBAK REJO', row: 6),
        line('RT/RW : 000/000', row: 7),
        line('Kel/Desa : TANAH RENDAH', row: 8),
        line('Kecamatan : AIR PUTIH', row: 9),
        line('Agama : ISLAM', row: 10),
        line('Status Perkawinan: BELUM KAWIN', row: 11),
        line('Pekerjaan : PNS', row: 12),
        line('Kewarganegaraan : WNI', row: 13),
        line('Berlaku Hingga : SEUMUR HIDUP', row: 14),
        line('18-09-2016', row: 13, left: 420, width: 90),
      ]);

      expect(outcome.recognized, isTrue);
      expect(valuesOf(outcome.data), {
        'Provinsi': 'SUMATERA UTARA',
        'Kabupaten / Kota': 'KABUPATEN BATUBARA',
        'NIK': '3674072257025008',
        'Nama': 'SYAIFUL ARIF',
        'Tempat Lahir': 'JAKARTA',
        'Tanggal Lahir': '22-04-1984',
        'Jenis Kelamin': 'LAKI-LAKI',
        'Alamat': 'TAMBAK REJO',
        'RT / RW': '000/000',
        'Kel / Desa': 'TANAH RENDAH',
        'Kecamatan': 'AIR PUTIH',
        'Agama': 'ISLAM',
        'Status Perkawinan': 'BELUM KAWIN',
        'Pekerjaan': 'PNS',
        'Kewarganegaraan': 'WNI',
        'Berlaku Hingga': 'SEUMUR HIDUP',
        'Tanggal Dikeluarkan': '18-09-2016',
      });
    });

    test('reads a card split into a label and a value column', () {
      OcrLine label(String text, int row) =>
          line(text, row: row, left: 10, width: 100);
      OcrLine colon(int row) => line(':', row: row, left: 120, width: 8);
      OcrLine value(String text, int row, {double left = 140}) =>
          line(text, row: row, left: left, width: 200);

      final outcome = parse([
        line('PROVINSI DKI JAKARTA', row: 0, left: 150, width: 240),
        line('JAKARTA TIMUR', row: 1, left: 180, width: 180),
        label('NIK', 2),
        colon(2),
        value('3175070101909999', 2),
        label('Nama', 3),
        colon(3),
        value('BILLY BUMBLEBEE SIFULAN', 3),
        label('Tempat/Tgl Lahir', 4),
        colon(4),
        value('SURABAYA, 01-01-1990', 4),
        label('Jenis Kelamin', 5),
        colon(5),
        value('LAKI-LAKI', 5, left: 140),
        line('Gol. Darah', row: 5, left: 260, width: 80),
        line(':', row: 5, left: 350, width: 8),
        line('AB', row: 5, left: 365, width: 30),
        label('Alamat', 6),
        colon(6),
        value('JL DIMANA NO 100', 6),
        label('RT/RW', 7),
        colon(7),
        value('001/001', 7),
        label('Kel/Desa', 8),
        colon(8),
        value('ANTAH BERANTAH', 8),
        label('Kecamatan', 9),
        colon(9),
        value('DUREN SAWIT', 9),
        label('Agama', 10),
        colon(10),
        value('ISLAM', 10),
        label('Status Perkawinan', 11),
        colon(11),
        value('KAWIN', 11),
        label('Pekerjaan', 12),
        colon(12),
        value('KARYAWAN SWASTA', 12),
        label('Kewarganegaraan', 13),
        colon(13),
        value('WNI', 13),
        label('Berlaku Hingga', 14),
        colon(14),
        value('SEUMUR HIDUP', 14),
        line('JAKARTA TIMUR', row: 13, left: 430, width: 120),
        line('01-01-2020', row: 14, left: 430, width: 120),
      ]);

      expect(valuesOf(outcome.data), {
        'Provinsi': 'DKI JAKARTA',
        'Kabupaten / Kota': 'JAKARTA TIMUR',
        'NIK': '3175070101909999',
        'Nama': 'BILLY BUMBLEBEE SIFULAN',
        'Tempat Lahir': 'SURABAYA',
        'Tanggal Lahir': '01-01-1990',
        'Jenis Kelamin': 'LAKI-LAKI',
        'Gol. Darah': 'AB',
        'Alamat': 'JL DIMANA NO 100',
        'RT / RW': '001/001',
        'Kel / Desa': 'ANTAH BERANTAH',
        'Kecamatan': 'DUREN SAWIT',
        'Agama': 'ISLAM',
        'Status Perkawinan': 'KAWIN',
        'Pekerjaan': 'KARYAWAN SWASTA',
        'Kewarganegaraan': 'WNI',
        'Berlaku Hingga': 'SEUMUR HIDUP',
        'Tempat Dikeluarkan': 'JAKARTA TIMUR',
        'Tanggal Dikeluarkan': '01-01-2020',
      });
    });

    test('repairs misread digits, typos and empty blood type', () {
      final outcome = parse([
        line('PROVINSI ACEH', row: 0, left: 150, width: 200),
        line('KABUPATEN BIREUEN', row: 1, left: 140, width: 220),
        line('N I K : llllll7ll275000l', row: 2),
        line('Nama : DARWATI', row: 3),
        line('Tempat/Tgl Lahir : SAMALANGA, 3l-l2-l975', row: 4),
        line('Jenis kelamin : PEREMPUAN Gol. Darah :-', row: 5),
        line('Alamat : DUSUN MALEM PAHLAWAN', row: 6),
        line('RT/RW : OOO/OOO', row: 7),
        line('Kel/Desa : ARONGAN', row: 8),
        line('Kocamatan : SIMPANG MAMPLAM', row: 9),
        line('Agama : lSLAM', row: 10),
        line('Status Perkawinan: KAWIN', row: 11),
        line('Pekerjaan : KARYAWAN HONORER', row: 12),
        line('Kewarganegaraan : WNl', row: 13),
        line('Berlaku Hingga : SEUMUR HlDUP', row: 14),
      ]);

      final values = valuesOf(outcome.data);
      expect(values['NIK'], '1111117112750001');
      expect(values['Tanggal Lahir'], '31-12-1975');
      expect(values['Jenis Kelamin'], 'PEREMPUAN');
      expect(values.containsKey('Gol. Darah'), isFalse);
      expect(values['RT / RW'], '000/000');
      expect(values['Kecamatan'], 'SIMPANG MAMPLAM');
      expect(values['Agama'], 'ISLAM');
      expect(values['Kewarganegaraan'], 'WNI');
      expect(values['Berlaku Hingga'], 'SEUMUR HIDUP');
    });

    test('lists the issuing region last', () {
      final data = parse([
        line('PROVINSI SUMATERA UTARA', row: 0, left: 120, width: 260),
        line('KABUPATEN BATUBARA', row: 1, left: 140, width: 220),
        line('NIK : 3674072257025008', row: 2),
        line('Nama : SYAIFUL ARIF', row: 3),
        line('Alamat : TAMBAK REJO', row: 4),
      ]).data;

      expect(data.fields.first.key, KtpFieldKey.nik);
      expect(data.fields.map((f) => f.key).toList().sublist(3), [
        KtpFieldKey.provinsi,
        KtpFieldKey.kabupatenKota,
      ]);
    });

    test('exposes typed getters and a serializable map', () {
      final data = parse([
        line('NIK : 3175070101909999', row: 0),
        line('Nama : BILLY BUMBLEBEE SIFULAN', row: 1),
        line('Alamat : JL DIMANA NO 100', row: 2),
      ]).data;

      expect(data.nik, '3175070101909999');
      expect(data.nama, 'BILLY BUMBLEBEE SIFULAN');
      expect(data.alamat, 'JL DIMANA NO 100');
      expect(data.kecamatan, isNull);
      expect(data.toMap()['nik'], '3175070101909999');
    });

    test('flags a document with no KTP keywords as unrecognized', () {
      final outcome = parse([
        line('KEMENTERIAN KEUANGAN REPUBLIK INDONESIA', row: 0),
        line('DIREKTORAT JENDERAL PAJAK', row: 1),
      ]);

      expect(outcome.recognized, isFalse);
    });
  });
}
