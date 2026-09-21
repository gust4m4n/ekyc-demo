/// Fields read off an Indonesian KTP. Declaration order is display order:
/// the holder's own details first, then where the card was issued.
enum KtpFieldKey {
  nik('NIK'),
  nama('Nama'),
  tempatLahir('Tempat Lahir'),
  tanggalLahir('Tanggal Lahir'),
  jenisKelamin('Jenis Kelamin'),
  golonganDarah('Gol. Darah'),
  alamat('Alamat'),
  rtRw('RT / RW'),
  kelurahanDesa('Kel / Desa'),
  kecamatan('Kecamatan'),
  agama('Agama'),
  statusPerkawinan('Status Perkawinan'),
  pekerjaan('Pekerjaan'),
  kewarganegaraan('Kewarganegaraan'),
  berlakuHingga('Berlaku Hingga'),
  tempatDikeluarkan('Tempat Dikeluarkan'),
  tanggalDikeluarkan('Tanggal Dikeluarkan'),
  provinsi('Provinsi'),
  kabupatenKota('Kabupaten / Kota');

  const KtpFieldKey(this.label);

  /// Indonesian label shown next to the value.
  final String label;
}

/// One value pulled out of the recognized text.
class KtpField {
  const KtpField(this.key, this.value);

  final KtpFieldKey key;
  final String value;

  String get label => key.label;
}

/// The fields extracted from a single card, ordered as printed.
class KtpData {
  const KtpData(this.fields);

  const KtpData.empty() : fields = const [];

  final List<KtpField> fields;

  bool get isEmpty => fields.isEmpty;
  bool get isNotEmpty => fields.isNotEmpty;

  /// Value of [key], or `null` when the field was not readable.
  String? operator [](KtpFieldKey key) {
    for (final field in fields) {
      if (field.key == key) return field.value;
    }
    return null;
  }

  String? get provinsi => this[KtpFieldKey.provinsi];
  String? get kabupatenKota => this[KtpFieldKey.kabupatenKota];
  String? get nik => this[KtpFieldKey.nik];
  String? get nama => this[KtpFieldKey.nama];
  String? get tempatLahir => this[KtpFieldKey.tempatLahir];
  String? get tanggalLahir => this[KtpFieldKey.tanggalLahir];
  String? get jenisKelamin => this[KtpFieldKey.jenisKelamin];
  String? get golonganDarah => this[KtpFieldKey.golonganDarah];
  String? get alamat => this[KtpFieldKey.alamat];
  String? get rtRw => this[KtpFieldKey.rtRw];
  String? get kelurahanDesa => this[KtpFieldKey.kelurahanDesa];
  String? get kecamatan => this[KtpFieldKey.kecamatan];
  String? get agama => this[KtpFieldKey.agama];
  String? get statusPerkawinan => this[KtpFieldKey.statusPerkawinan];
  String? get pekerjaan => this[KtpFieldKey.pekerjaan];
  String? get kewarganegaraan => this[KtpFieldKey.kewarganegaraan];
  String? get berlakuHingga => this[KtpFieldKey.berlakuHingga];
  String? get tempatDikeluarkan => this[KtpFieldKey.tempatDikeluarkan];
  String? get tanggalDikeluarkan => this[KtpFieldKey.tanggalDikeluarkan];

  /// Enum-name keyed map, handy for JSON payloads.
  Map<String, String> toMap() => {
    for (final field in fields) field.key.name: field.value,
  };
}
