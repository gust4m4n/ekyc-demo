import 'package:flutter/foundation.dart';

/// Administrative areas used by the cascading address picker.
///
/// The tree is a representative subset (province → city/regency → district),
/// not the full national registry: the demo only needs enough depth to show
/// the three dependent dropdowns. Names are stored upper case so they match
/// the rest of the form.
@immutable
class IdCity {
  const IdCity({required this.name, required this.districts});

  final String name;
  final List<String> districts;
}

@immutable
class IdProvince {
  const IdProvince({required this.name, required this.cities});

  final String name;
  final List<IdCity> cities;
}

IdProvince? provinceByName(String? name) {
  if (name == null) return null;
  for (final province in kIndonesiaProvinces) {
    if (province.name == name) return province;
  }
  return null;
}

IdCity? cityByName(IdProvince? province, String? name) {
  if (province == null || name == null) return null;
  for (final city in province.cities) {
    if (city.name == name) return city;
  }
  return null;
}

const List<IdProvince> kIndonesiaProvinces = [
  IdProvince(
    name: 'ACEH',
    cities: [
      IdCity(
        name: 'KOTA BANDA ACEH',
        districts: ['BAITURRAHMAN', 'KUTA ALAM', 'SYIAH KUALA', 'MEURAXA'],
      ),
      IdCity(
        name: 'KOTA LHOKSEUMAWE',
        districts: ['BANDA SAKTI', 'MUARA DUA', 'MUARA SATU', 'BLANG MANGAT'],
      ),
      IdCity(
        name: 'KABUPATEN ACEH BESAR',
        districts: [
          'INGIN JAYA',
          'DARUL IMARAH',
          'KRUENG BARONA JAYA',
          'BAITUSSALAM',
        ],
      ),
      IdCity(
        name: 'KABUPATEN PIDIE',
        districts: ['SIGLI', 'MUTIARA', 'DELIMA', 'INDRAJAYA'],
      ),
    ],
  ),
  IdProvince(
    name: 'SUMATERA UTARA',
    cities: [
      IdCity(
        name: 'KOTA MEDAN',
        districts: [
          'MEDAN KOTA',
          'MEDAN BARU',
          'MEDAN JOHOR',
          'MEDAN SUNGGAL',
          'MEDAN TUNTUNGAN',
        ],
      ),
      IdCity(
        name: 'KOTA BINJAI',
        districts: [
          'BINJAI KOTA',
          'BINJAI UTARA',
          'BINJAI TIMUR',
          'BINJAI SELATAN',
        ],
      ),
      IdCity(
        name: 'KOTA PEMATANGSIANTAR',
        districts: [
          'SIANTAR BARAT',
          'SIANTAR TIMUR',
          'SIANTAR UTARA',
          'SIANTAR SELATAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN DELI SERDANG',
        districts: [
          'LUBUK PAKAM',
          'TANJUNG MORAWA',
          'PERCUT SEI TUAN',
          'SUNGGAL',
        ],
      ),
    ],
  ),
  IdProvince(
    name: 'SUMATERA BARAT',
    cities: [
      IdCity(
        name: 'KOTA PADANG',
        districts: [
          'PADANG BARAT',
          'PADANG TIMUR',
          'KOTO TANGAH',
          'KURANJI',
          'LUBUK BEGALUNG',
        ],
      ),
      IdCity(
        name: 'KOTA BUKITTINGGI',
        districts: [
          'GUGUK PANJANG',
          'MANDIANGIN KOTO SELAYAN',
          'AUR BIRUGO TIGO BALEH',
        ],
      ),
      IdCity(
        name: 'KOTA PAYAKUMBUH',
        districts: [
          'PAYAKUMBUH BARAT',
          'PAYAKUMBUH TIMUR',
          'PAYAKUMBUH UTARA',
          'PAYAKUMBUH SELATAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN AGAM',
        districts: ['LUBUK BASUNG', 'TILATANG KAMANG', 'BASO', 'BANUHAMPU'],
      ),
    ],
  ),
  IdProvince(
    name: 'RIAU',
    cities: [
      IdCity(
        name: 'KOTA PEKANBARU',
        districts: [
          'SUKAJADI',
          'SAIL',
          'TAMPAN',
          'MARPOYAN DAMAI',
          'BUKIT RAYA',
        ],
      ),
      IdCity(
        name: 'KOTA DUMAI',
        districts: [
          'DUMAI KOTA',
          'DUMAI BARAT',
          'DUMAI TIMUR',
          'DUMAI SELATAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KAMPAR',
        districts: ['BANGKINANG', 'TAMBANG', 'SIAK HULU', 'KAMPAR'],
      ),
      IdCity(
        name: 'KABUPATEN SIAK',
        districts: ['SIAK', 'TUALANG', 'MINAS', 'KANDIS'],
      ),
    ],
  ),
  IdProvince(
    name: 'KEPULAUAN RIAU',
    cities: [
      IdCity(
        name: 'KOTA BATAM',
        districts: [
          'BATAM KOTA',
          'LUBUK BAJA',
          'SEKUPANG',
          'NONGSA',
          'BATU AJI',
        ],
      ),
      IdCity(
        name: 'KOTA TANJUNGPINANG',
        districts: [
          'TANJUNGPINANG KOTA',
          'TANJUNGPINANG BARAT',
          'TANJUNGPINANG TIMUR',
          'BUKIT BESTARI',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BINTAN',
        districts: [
          'BINTAN TIMUR',
          'BINTAN UTARA',
          'TELUK BINTAN',
          'GUNUNG KIJANG',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KARIMUN',
        districts: ['KARIMUN', 'MERAL', 'TEBING', 'BURU'],
      ),
    ],
  ),
  IdProvince(
    name: 'JAMBI',
    cities: [
      IdCity(
        name: 'KOTA JAMBI',
        districts: [
          'TELANAIPURA',
          'JELUTUNG',
          'PASAR JAMBI',
          'KOTA BARU',
          'JAMBI SELATAN',
        ],
      ),
      IdCity(
        name: 'KOTA SUNGAI PENUH',
        districts: [
          'SUNGAI PENUH',
          'PESISIR BUKIT',
          'HAMPARAN RAWANG',
          'KUMUN DEBAI',
        ],
      ),
      IdCity(
        name: 'KABUPATEN MUARO JAMBI',
        districts: ['SEKERNAN', 'JAMBI LUAR KOTA', 'MESTONG', 'KUMPEH'],
      ),
      IdCity(
        name: 'KABUPATEN BATANGHARI',
        districts: ['MUARA BULIAN', 'MUARA TEMBESI', 'MERSAM', 'PEMAYUNG'],
      ),
    ],
  ),
  IdProvince(
    name: 'SUMATERA SELATAN',
    cities: [
      IdCity(
        name: 'KOTA PALEMBANG',
        districts: [
          'ILIR BARAT I',
          'ILIR TIMUR I',
          'SEBERANG ULU I',
          'KEMUNING',
          'SUKARAMI',
        ],
      ),
      IdCity(
        name: 'KOTA PRABUMULIH',
        districts: [
          'PRABUMULIH BARAT',
          'PRABUMULIH TIMUR',
          'PRABUMULIH UTARA',
          'PRABUMULIH SELATAN',
        ],
      ),
      IdCity(
        name: 'KOTA LUBUKLINGGAU',
        districts: [
          'LUBUKLINGGAU BARAT I',
          'LUBUKLINGGAU TIMUR I',
          'LUBUKLINGGAU UTARA I',
          'LUBUKLINGGAU SELATAN I',
        ],
      ),
      IdCity(
        name: 'KABUPATEN OGAN ILIR',
        districts: ['INDRALAYA', 'TANJUNG RAJA', 'PEMULUTAN', 'RANTAU PANJANG'],
      ),
    ],
  ),
  IdProvince(
    name: 'BENGKULU',
    cities: [
      IdCity(
        name: 'KOTA BENGKULU',
        districts: [
          'GADING CEMPAKA',
          'TELUK SEGARA',
          'RATU AGUNG',
          'SELEBAR',
          'MUARA BANGKAHULU',
        ],
      ),
      IdCity(
        name: 'KABUPATEN REJANG LEBONG',
        districts: ['CURUP', 'CURUP UTARA', 'CURUP SELATAN', 'SELUPU REJANG'],
      ),
      IdCity(
        name: 'KABUPATEN BENGKULU UTARA',
        districts: ['ARGA MAKMUR', 'KERKAP', 'LAIS', 'PADANG JAYA'],
      ),
      IdCity(
        name: 'KABUPATEN SELUMA',
        districts: ['TAIS', 'SUKARAJA', 'SELUMA', 'TALO'],
      ),
    ],
  ),
  IdProvince(
    name: 'LAMPUNG',
    cities: [
      IdCity(
        name: 'KOTA BANDAR LAMPUNG',
        districts: [
          'TANJUNG KARANG PUSAT',
          'KEDATON',
          'RAJABASA',
          'SUKARAME',
          'TELUK BETUNG SELATAN',
        ],
      ),
      IdCity(
        name: 'KOTA METRO',
        districts: ['METRO PUSAT', 'METRO BARAT', 'METRO TIMUR', 'METRO UTARA'],
      ),
      IdCity(
        name: 'KABUPATEN LAMPUNG SELATAN',
        districts: ['KALIANDA', 'NATAR', 'JATI AGUNG', 'TANJUNG BINTANG'],
      ),
      IdCity(
        name: 'KABUPATEN PRINGSEWU',
        districts: ['PRINGSEWU', 'GADINGREJO', 'AMBARAWA', 'SUKOHARJO'],
      ),
    ],
  ),
  IdProvince(
    name: 'KEPULAUAN BANGKA BELITUNG',
    cities: [
      IdCity(
        name: 'KOTA PANGKALPINANG',
        districts: [
          'TAMAN SARI',
          'RANGKUI',
          'BUKIT INTAN',
          'GERUNGGANG',
          'GABEK',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BANGKA',
        districts: ['SUNGAILIAT', 'MERAWANG', 'BELINYU', 'PEMALI'],
      ),
      IdCity(
        name: 'KABUPATEN BELITUNG',
        districts: ['TANJUNG PANDAN', 'SIJUK', 'BADAU', 'MEMBALONG'],
      ),
      IdCity(
        name: 'KABUPATEN BANGKA BARAT',
        districts: ['MUNTOK', 'TEMPILANG', 'JEBUS', 'KELAPA'],
      ),
    ],
  ),
  IdProvince(
    name: 'DKI JAKARTA',
    cities: [
      IdCity(
        name: 'KOTA JAKARTA PUSAT',
        districts: [
          'GAMBIR',
          'TANAH ABANG',
          'MENTENG',
          'SENEN',
          'CEMPAKA PUTIH',
        ],
      ),
      IdCity(
        name: 'KOTA JAKARTA UTARA',
        districts: [
          'TANJUNG PRIOK',
          'KELAPA GADING',
          'PENJARINGAN',
          'KOJA',
          'CILINCING',
        ],
      ),
      IdCity(
        name: 'KOTA JAKARTA BARAT',
        districts: [
          'GROGOL PETAMBURAN',
          'TAMBORA',
          'KEBON JERUK',
          'KEMBANGAN',
          'CENGKARENG',
        ],
      ),
      IdCity(
        name: 'KOTA JAKARTA SELATAN',
        districts: [
          'KEBAYORAN BARU',
          'TEBET',
          'PANCORAN',
          'CILANDAK',
          'PASAR MINGGU',
        ],
      ),
      IdCity(
        name: 'KOTA JAKARTA TIMUR',
        districts: [
          'MATRAMAN',
          'JATINEGARA',
          'DUREN SAWIT',
          'CAKUNG',
          'PULO GADUNG',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KEPULAUAN SERIBU',
        districts: ['KEPULAUAN SERIBU UTARA', 'KEPULAUAN SERIBU SELATAN'],
      ),
    ],
  ),
  IdProvince(
    name: 'JAWA BARAT',
    cities: [
      IdCity(
        name: 'KOTA BANDUNG',
        districts: [
          'COBLONG',
          'SUKAJADI',
          'CIDADAP',
          'BANDUNG WETAN',
          'LENGKONG',
          'BUAHBATU',
        ],
      ),
      IdCity(
        name: 'KOTA BEKASI',
        districts: [
          'BEKASI TIMUR',
          'BEKASI BARAT',
          'BEKASI SELATAN',
          'BEKASI UTARA',
          'PONDOK GEDE',
        ],
      ),
      IdCity(
        name: 'KOTA DEPOK',
        districts: [
          'BEJI',
          'PANCORAN MAS',
          'CIMANGGIS',
          'SUKMAJAYA',
          'SAWANGAN',
        ],
      ),
      IdCity(
        name: 'KOTA BOGOR',
        districts: [
          'BOGOR TENGAH',
          'BOGOR UTARA',
          'BOGOR SELATAN',
          'BOGOR BARAT',
          'TANAH SAREAL',
        ],
      ),
      IdCity(
        name: 'KOTA CIMAHI',
        districts: ['CIMAHI UTARA', 'CIMAHI TENGAH', 'CIMAHI SELATAN'],
      ),
      IdCity(
        name: 'KABUPATEN BANDUNG',
        districts: [
          'SOREANG',
          'BALEENDAH',
          'MAJALAYA',
          'CILEUNYI',
          'DAYEUHKOLOT',
        ],
      ),
    ],
  ),
  IdProvince(
    name: 'BANTEN',
    cities: [
      IdCity(
        name: 'KOTA TANGERANG',
        districts: [
          'TANGERANG',
          'CIPONDOH',
          'KARAWACI',
          'CILEDUG',
          'BATUCEPER',
        ],
      ),
      IdCity(
        name: 'KOTA TANGERANG SELATAN',
        districts: [
          'SERPONG',
          'SERPONG UTARA',
          'PONDOK AREN',
          'CIPUTAT',
          'PAMULANG',
        ],
      ),
      IdCity(
        name: 'KOTA SERANG',
        districts: ['SERANG', 'CIPOCOK JAYA', 'TAKTAKAN', 'KASEMEN'],
      ),
      IdCity(
        name: 'KOTA CILEGON',
        districts: ['CILEGON', 'CIBEBER', 'JOMBANG', 'GROGOL'],
      ),
      IdCity(
        name: 'KABUPATEN TANGERANG',
        districts: ['TIGARAKSA', 'CURUG', 'KELAPA DUA', 'PASAR KEMIS'],
      ),
    ],
  ),
  IdProvince(
    name: 'JAWA TENGAH',
    cities: [
      IdCity(
        name: 'KOTA SEMARANG',
        districts: [
          'SEMARANG TENGAH',
          'SEMARANG SELATAN',
          'TEMBALANG',
          'BANYUMANIK',
          'GAJAHMUNGKUR',
        ],
      ),
      IdCity(
        name: 'KOTA SURAKARTA',
        districts: [
          'LAWEYAN',
          'SERENGAN',
          'PASAR KLIWON',
          'JEBRES',
          'BANJARSARI',
        ],
      ),
      IdCity(
        name: 'KOTA SALATIGA',
        districts: ['SIDOREJO', 'TINGKIR', 'ARGOMULYO', 'SIDOMUKTI'],
      ),
      IdCity(
        name: 'KOTA PEKALONGAN',
        districts: [
          'PEKALONGAN BARAT',
          'PEKALONGAN TIMUR',
          'PEKALONGAN UTARA',
          'PEKALONGAN SELATAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BANYUMAS',
        districts: [
          'PURWOKERTO TIMUR',
          'PURWOKERTO BARAT',
          'SOKARAJA',
          'BATURRADEN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KUDUS',
        districts: ['KOTA KUDUS', 'JATI', 'BAE', 'GEBOG'],
      ),
    ],
  ),
  IdProvince(
    name: 'DI YOGYAKARTA',
    cities: [
      IdCity(
        name: 'KOTA YOGYAKARTA',
        districts: [
          'GONDOKUSUMAN',
          'UMBULHARJO',
          'MERGANGSAN',
          'JETIS',
          'KRATON',
        ],
      ),
      IdCity(
        name: 'KABUPATEN SLEMAN',
        districts: ['DEPOK', 'MLATI', 'GAMPING', 'NGAGLIK', 'KALASAN'],
      ),
      IdCity(
        name: 'KABUPATEN BANTUL',
        districts: ['BANGUNTAPAN', 'KASIHAN', 'SEWON', 'BANTUL'],
      ),
      IdCity(
        name: 'KABUPATEN KULON PROGO',
        districts: ['WATES', 'PENGASIH', 'SENTOLO', 'TEMON'],
      ),
      IdCity(
        name: 'KABUPATEN GUNUNGKIDUL',
        districts: ['WONOSARI', 'PLAYEN', 'KARANGMOJO', 'SEMANU'],
      ),
    ],
  ),
  IdProvince(
    name: 'JAWA TIMUR',
    cities: [
      IdCity(
        name: 'KOTA SURABAYA',
        districts: [
          'GUBENG',
          'TEGALSARI',
          'WONOKROMO',
          'SUKOLILO',
          'RUNGKUT',
          'MULYOREJO',
        ],
      ),
      IdCity(
        name: 'KOTA MALANG',
        districts: [
          'KLOJEN',
          'LOWOKWARU',
          'BLIMBING',
          'SUKUN',
          'KEDUNGKANDANG',
        ],
      ),
      IdCity(name: 'KOTA KEDIRI', districts: ['KOTA', 'MOJOROTO', 'PESANTREN']),
      IdCity(
        name: 'KABUPATEN SIDOARJO',
        districts: ['SIDOARJO', 'WARU', 'TAMAN', 'GEDANGAN', 'KRIAN'],
      ),
      IdCity(
        name: 'KABUPATEN GRESIK',
        districts: ['GRESIK', 'KEBOMAS', 'MANYAR', 'DRIYOREJO'],
      ),
    ],
  ),
  IdProvince(
    name: 'BALI',
    cities: [
      IdCity(
        name: 'KOTA DENPASAR',
        districts: [
          'DENPASAR BARAT',
          'DENPASAR TIMUR',
          'DENPASAR SELATAN',
          'DENPASAR UTARA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BADUNG',
        districts: [
          'KUTA',
          'KUTA SELATAN',
          'KUTA UTARA',
          'MENGWI',
          'ABIANSEMAL',
        ],
      ),
      IdCity(
        name: 'KABUPATEN GIANYAR',
        districts: ['GIANYAR', 'UBUD', 'SUKAWATI', 'BLAHBATUH'],
      ),
      IdCity(
        name: 'KABUPATEN BULELENG',
        districts: ['BULELENG', 'SUKASADA', 'SERIRIT', 'BANJAR'],
      ),
      IdCity(
        name: 'KABUPATEN TABANAN',
        districts: ['TABANAN', 'KEDIRI', 'MARGA', 'BATURITI'],
      ),
    ],
  ),
  IdProvince(
    name: 'NUSA TENGGARA BARAT',
    cities: [
      IdCity(
        name: 'KOTA MATARAM',
        districts: [
          'MATARAM',
          'CAKRANEGARA',
          'SELAPARANG',
          'AMPENAN',
          'SEKARBELA',
        ],
      ),
      IdCity(
        name: 'KOTA BIMA',
        districts: ['RASANAE BARAT', 'RASANAE TIMUR', 'MPUNDA', 'RABA'],
      ),
      IdCity(
        name: 'KABUPATEN LOMBOK BARAT',
        districts: ['GERUNG', 'NARMADA', 'LABUAPI', 'KEDIRI'],
      ),
      IdCity(
        name: 'KABUPATEN SUMBAWA',
        districts: ['SUMBAWA', 'MOYO HILIR', 'UTAN', 'ALAS'],
      ),
    ],
  ),
  IdProvince(
    name: 'NUSA TENGGARA TIMUR',
    cities: [
      IdCity(
        name: 'KOTA KUPANG',
        districts: ['OEBOBO', 'KELAPA LIMA', 'KOTA RAJA', 'ALAK', 'MAULAFA'],
      ),
      IdCity(
        name: 'KABUPATEN SIKKA',
        districts: ['ALOK', 'ALOK TIMUR', 'ALOK BARAT', 'NITA'],
      ),
      IdCity(
        name: 'KABUPATEN BELU',
        districts: [
          'KOTA ATAMBUA',
          'ATAMBUA BARAT',
          'ATAMBUA SELATAN',
          'TASIFETO TIMUR',
        ],
      ),
      IdCity(
        name: 'KABUPATEN MANGGARAI',
        districts: ['LANGKE REMBONG', 'RUTENG', 'CIBAL', 'REOK'],
      ),
    ],
  ),
  IdProvince(
    name: 'KALIMANTAN BARAT',
    cities: [
      IdCity(
        name: 'KOTA PONTIANAK',
        districts: [
          'PONTIANAK KOTA',
          'PONTIANAK SELATAN',
          'PONTIANAK BARAT',
          'PONTIANAK TIMUR',
          'PONTIANAK UTARA',
        ],
      ),
      IdCity(
        name: 'KOTA SINGKAWANG',
        districts: [
          'SINGKAWANG BARAT',
          'SINGKAWANG TENGAH',
          'SINGKAWANG UTARA',
          'SINGKAWANG SELATAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KUBU RAYA',
        districts: [
          'SUNGAI RAYA',
          'SUNGAI KAKAP',
          'RASAU JAYA',
          'SUNGAI AMBAWANG',
        ],
      ),
      IdCity(
        name: 'KABUPATEN SANGGAU',
        districts: ['KAPUAS', 'PARINDU', 'TAYAN HILIR', 'BONTI'],
      ),
    ],
  ),
  IdProvince(
    name: 'KALIMANTAN TENGAH',
    cities: [
      IdCity(
        name: 'KOTA PALANGKA RAYA',
        districts: ['PAHANDUT', 'JEKAN RAYA', 'SABANGAU', 'BUKIT BATU'],
      ),
      IdCity(
        name: 'KABUPATEN KOTAWARINGIN TIMUR',
        districts: [
          'MENTAWA BARU KETAPANG',
          'BAAMANG',
          'KOTA BESI',
          'PARENGGEAN',
        ],
      ),
      IdCity(
        name: 'KABUPATEN KOTAWARINGIN BARAT',
        districts: ['ARUT SELATAN', 'ARUT UTARA', 'KUMAI', 'PANGKALAN LADA'],
      ),
      IdCity(
        name: 'KABUPATEN KAPUAS',
        districts: ['SELAT', 'BASARANG', 'KAPUAS HILIR', 'PULAU PETAK'],
      ),
    ],
  ),
  IdProvince(
    name: 'KALIMANTAN SELATAN',
    cities: [
      IdCity(
        name: 'KOTA BANJARMASIN',
        districts: [
          'BANJARMASIN TENGAH',
          'BANJARMASIN UTARA',
          'BANJARMASIN SELATAN',
          'BANJARMASIN TIMUR',
          'BANJARMASIN BARAT',
        ],
      ),
      IdCity(
        name: 'KOTA BANJARBARU',
        districts: [
          'BANJARBARU UTARA',
          'BANJARBARU SELATAN',
          'LANDASAN ULIN',
          'CEMPAKA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BANJAR',
        districts: ['MARTAPURA', 'MARTAPURA TIMUR', 'GAMBUT', 'SUNGAI TABUK'],
      ),
      IdCity(
        name: 'KABUPATEN TANAH LAUT',
        districts: ['PELAIHARI', 'BATI-BATI', 'KURAU', 'TAKISUNG'],
      ),
    ],
  ),
  IdProvince(
    name: 'KALIMANTAN TIMUR',
    cities: [
      IdCity(
        name: 'KOTA SAMARINDA',
        districts: [
          'SAMARINDA ULU',
          'SAMARINDA KOTA',
          'SAMARINDA SEBERANG',
          'SUNGAI KUNJANG',
          'SAMARINDA UTARA',
        ],
      ),
      IdCity(
        name: 'KOTA BALIKPAPAN',
        districts: [
          'BALIKPAPAN SELATAN',
          'BALIKPAPAN UTARA',
          'BALIKPAPAN TENGAH',
          'BALIKPAPAN TIMUR',
          'BALIKPAPAN BARAT',
        ],
      ),
      IdCity(
        name: 'KOTA BONTANG',
        districts: ['BONTANG UTARA', 'BONTANG SELATAN', 'BONTANG BARAT'],
      ),
      IdCity(
        name: 'KABUPATEN KUTAI KARTANEGARA',
        districts: ['TENGGARONG', 'TENGGARONG SEBERANG', 'LOA KULU', 'SEBULU'],
      ),
    ],
  ),
  IdProvince(
    name: 'KALIMANTAN UTARA',
    cities: [
      IdCity(
        name: 'KOTA TARAKAN',
        districts: [
          'TARAKAN TENGAH',
          'TARAKAN BARAT',
          'TARAKAN TIMUR',
          'TARAKAN UTARA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN BULUNGAN',
        districts: [
          'TANJUNG SELOR',
          'TANJUNG PALAS',
          'TANJUNG PALAS TENGAH',
          'SEKATAK',
        ],
      ),
      IdCity(
        name: 'KABUPATEN NUNUKAN',
        districts: ['NUNUKAN', 'NUNUKAN SELATAN', 'SEBATIK', 'SEBATIK BARAT'],
      ),
      IdCity(
        name: 'KABUPATEN MALINAU',
        districts: [
          'MALINAU KOTA',
          'MALINAU BARAT',
          'MALINAU UTARA',
          'MALINAU SELATAN',
        ],
      ),
    ],
  ),
  IdProvince(
    name: 'SULAWESI UTARA',
    cities: [
      IdCity(
        name: 'KOTA MANADO',
        districts: ['WENANG', 'SARIO', 'MALALAYANG', 'TIKALA', 'MAPANGET'],
      ),
      IdCity(
        name: 'KOTA BITUNG',
        districts: ['MADIDIR', 'MAESA', 'GIRIAN', 'AERTEMBAGA'],
      ),
      IdCity(
        name: 'KOTA TOMOHON',
        districts: [
          'TOMOHON UTARA',
          'TOMOHON TENGAH',
          'TOMOHON SELATAN',
          'TOMOHON BARAT',
        ],
      ),
      IdCity(
        name: 'KABUPATEN MINAHASA',
        districts: [
          'TONDANO BARAT',
          'TONDANO TIMUR',
          'TONDANO SELATAN',
          'TONDANO UTARA',
        ],
      ),
    ],
  ),
  IdProvince(
    name: 'GORONTALO',
    cities: [
      IdCity(
        name: 'KOTA GORONTALO',
        districts: [
          'KOTA TENGAH',
          'KOTA SELATAN',
          'KOTA UTARA',
          'KOTA BARAT',
          'DUNGINGI',
        ],
      ),
      IdCity(
        name: 'KABUPATEN GORONTALO',
        districts: ['LIMBOTO', 'TELAGA', 'TIBAWA', 'BATUDAA'],
      ),
      IdCity(
        name: 'KABUPATEN BONE BOLANGO',
        districts: ['SUWAWA', 'KABILA', 'TILONGKABILA', 'BOTUPINGGE'],
      ),
      IdCity(
        name: 'KABUPATEN BOALEMO',
        districts: ['TILAMUTA', 'DULUPI', 'PAGUYAMAN', 'WONOSARI'],
      ),
    ],
  ),
  IdProvince(
    name: 'SULAWESI TENGAH',
    cities: [
      IdCity(
        name: 'KOTA PALU',
        districts: [
          'PALU BARAT',
          'PALU TIMUR',
          'PALU SELATAN',
          'PALU UTARA',
          'TATANGA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN DONGGALA',
        districts: ['BANAWA', 'BANAWA SELATAN', 'LABUAN', 'SIRENJA'],
      ),
      IdCity(
        name: 'KABUPATEN POSO',
        districts: ['POSO KOTA', 'POSO PESISIR', 'LAGE', 'PAMONA UTARA'],
      ),
      IdCity(
        name: 'KABUPATEN BANGGAI',
        districts: ['LUWUK', 'LUWUK SELATAN', 'LUWUK UTARA', 'KINTOM'],
      ),
    ],
  ),
  IdProvince(
    name: 'SULAWESI BARAT',
    cities: [
      IdCity(
        name: 'KABUPATEN MAMUJU',
        districts: ['MAMUJU', 'KALUKKU', 'SIMBORO', 'TAPALANG'],
      ),
      IdCity(
        name: 'KABUPATEN POLEWALI MANDAR',
        districts: ['POLEWALI', 'BINUANG', 'WONOMULYO', 'CAMPALAGIAN'],
      ),
      IdCity(
        name: 'KABUPATEN MAJENE',
        districts: ['BANGGAE', 'BANGGAE TIMUR', 'PAMBOANG', 'SENDANA'],
      ),
      IdCity(
        name: 'KABUPATEN MAMASA',
        districts: ['MAMASA', 'BALLA', 'TANDUKKALUA', 'SUMARORONG'],
      ),
    ],
  ),
  IdProvince(
    name: 'SULAWESI SELATAN',
    cities: [
      IdCity(
        name: 'KOTA MAKASSAR',
        districts: [
          'UJUNG PANDANG',
          'MAKASSAR',
          'PANAKKUKANG',
          'TAMALANREA',
          'RAPPOCINI',
          'BIRINGKANAYA',
        ],
      ),
      IdCity(
        name: 'KOTA PAREPARE',
        districts: ['BACUKIKI', 'BACUKIKI BARAT', 'UJUNG', 'SOREANG'],
      ),
      IdCity(
        name: 'KOTA PALOPO',
        districts: ['WARA', 'WARA UTARA', 'WARA SELATAN', 'TELLUWANUA'],
      ),
      IdCity(
        name: 'KABUPATEN GOWA',
        districts: ['SOMBA OPU', 'PALLANGGA', 'BAJENG', 'BONTOMARANNU'],
      ),
    ],
  ),
  IdProvince(
    name: 'SULAWESI TENGGARA',
    cities: [
      IdCity(
        name: 'KOTA KENDARI',
        districts: ['KENDARI', 'KENDARI BARAT', 'MANDONGA', 'PUUWATU', 'KADIA'],
      ),
      IdCity(
        name: 'KOTA BAUBAU',
        districts: ['WOLIO', 'BETOAMBARI', 'MURHUM', 'KOKALUKUNA', 'SORAWOLIO'],
      ),
      IdCity(
        name: 'KABUPATEN KONAWE',
        districts: ['UNAAHA', 'WAWOTOBI', 'PONDIDAHA', 'ABUKI'],
      ),
      IdCity(
        name: 'KABUPATEN KOLAKA',
        districts: ['KOLAKA', 'LATAMBAGA', 'WUNDULAKO', 'POMALAA'],
      ),
    ],
  ),
  IdProvince(
    name: 'MALUKU',
    cities: [
      IdCity(
        name: 'KOTA AMBON',
        districts: [
          'SIRIMAU',
          'NUSANIWE',
          'TELUK AMBON',
          'BAGUALA',
          'LEITIMUR SELATAN',
        ],
      ),
      IdCity(
        name: 'KOTA TUAL',
        districts: [
          'PULAU DULLAH UTARA',
          'PULAU DULLAH SELATAN',
          'TAYANDO TAM',
          'PULAU-PULAU KUR',
        ],
      ),
      IdCity(
        name: 'KABUPATEN MALUKU TENGAH',
        districts: ['KOTA MASOHI', 'AMAHAI', 'TEHORU', 'SAPARUA'],
      ),
      IdCity(
        name: 'KABUPATEN SERAM BAGIAN BARAT',
        districts: ['KAIRATU', 'SERAM BARAT', 'HUAMUAL', 'TANIWEL'],
      ),
    ],
  ),
  IdProvince(
    name: 'MALUKU UTARA',
    cities: [
      IdCity(
        name: 'KOTA TERNATE',
        districts: [
          'TERNATE TENGAH',
          'TERNATE SELATAN',
          'TERNATE UTARA',
          'PULAU TERNATE',
        ],
      ),
      IdCity(
        name: 'KOTA TIDORE KEPULAUAN',
        districts: ['TIDORE', 'TIDORE UTARA', 'TIDORE SELATAN', 'OBA'],
      ),
      IdCity(
        name: 'KABUPATEN HALMAHERA UTARA',
        districts: ['TOBELO', 'TOBELO SELATAN', 'TOBELO UTARA', 'GALELA'],
      ),
      IdCity(
        name: 'KABUPATEN HALMAHERA SELATAN',
        districts: ['BACAN', 'BACAN TIMUR', 'OBI', 'GANE BARAT'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA',
    cities: [
      IdCity(
        name: 'KOTA JAYAPURA',
        districts: [
          'JAYAPURA UTARA',
          'JAYAPURA SELATAN',
          'ABEPURA',
          'HERAM',
          'MUARA TAMI',
        ],
      ),
      IdCity(
        name: 'KABUPATEN JAYAPURA',
        districts: ['SENTANI', 'SENTANI TIMUR', 'SENTANI BARAT', 'WAIBU'],
      ),
      IdCity(
        name: 'KABUPATEN BIAK NUMFOR',
        districts: ['BIAK KOTA', 'SAMOFA', 'BIAK UTARA', 'BIAK TIMUR'],
      ),
      IdCity(
        name: 'KABUPATEN KEEROM',
        districts: ['ARSO', 'ARSO TIMUR', 'SKANTO', 'WARIS'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA BARAT',
    cities: [
      IdCity(
        name: 'KABUPATEN MANOKWARI',
        districts: [
          'MANOKWARI BARAT',
          'MANOKWARI TIMUR',
          'MANOKWARI SELATAN',
          'PRAFI',
        ],
      ),
      IdCity(
        name: 'KABUPATEN FAKFAK',
        districts: ['FAKFAK', 'FAKFAK TENGAH', 'FAKFAK BARAT', 'FAKFAK TIMUR'],
      ),
      IdCity(
        name: 'KABUPATEN KAIMANA',
        districts: ['KAIMANA', 'BURUWAY', 'TELUK ARGUNI', 'KAMBRAU'],
      ),
      IdCity(
        name: 'KABUPATEN TELUK BINTUNI',
        districts: ['BINTUNI', 'MANIMERI', 'TUHIBA', 'ARANDAY'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA BARAT DAYA',
    cities: [
      IdCity(
        name: 'KOTA SORONG',
        districts: [
          'SORONG',
          'SORONG TIMUR',
          'SORONG BARAT',
          'SORONG UTARA',
          'MALAIMSIMSA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN SORONG',
        districts: ['AIMAS', 'MARIAT', 'SALAWATI', 'MAYAMUK'],
      ),
      IdCity(
        name: 'KABUPATEN RAJA AMPAT',
        districts: [
          'WAISAI KOTA',
          'WAIGEO SELATAN',
          'SALAWATI UTARA',
          'MISOOL',
        ],
      ),
      IdCity(
        name: 'KABUPATEN TAMBRAUW',
        districts: ['FEF', 'SAUSAPOR', 'KWOOR', 'ABUN'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA SELATAN',
    cities: [
      IdCity(
        name: 'KABUPATEN MERAUKE',
        districts: ['MERAUKE', 'SEMANGGA', 'TANAH MIRING', 'KURIK'],
      ),
      IdCity(
        name: 'KABUPATEN BOVEN DIGOEL',
        districts: ['MANDOBO', 'MINDIPTANA', 'JAIR', 'KOUH'],
      ),
      IdCity(
        name: 'KABUPATEN MAPPI',
        districts: ['OBAA', 'EDERA', 'HAJU', 'ASSUE'],
      ),
      IdCity(
        name: 'KABUPATEN ASMAT',
        districts: ['AGATS', 'ATSJ', 'SAWA ERMA', 'AKAT'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA TENGAH',
    cities: [
      IdCity(
        name: 'KABUPATEN NABIRE',
        districts: ['NABIRE', 'NABIRE BARAT', 'TELUK KIMI', 'WANGGAR'],
      ),
      IdCity(
        name: 'KABUPATEN MIMIKA',
        districts: [
          'MIMIKA BARU',
          'KUALA KENCANA',
          'MIMIKA TIMUR',
          'TEMBAGAPURA',
        ],
      ),
      IdCity(
        name: 'KABUPATEN PANIAI',
        districts: ['PANIAI TIMUR', 'PANIAI BARAT', 'ARADIDE', 'BOGOBAIDA'],
      ),
      IdCity(
        name: 'KABUPATEN PUNCAK JAYA',
        districts: ['MULIA', 'ILU', 'FAWI', 'TORERE'],
      ),
    ],
  ),
  IdProvince(
    name: 'PAPUA PEGUNUNGAN',
    cities: [
      IdCity(
        name: 'KABUPATEN JAYAWIJAYA',
        districts: ['WAMENA', 'WALELAGAMA', 'ASOLOGAIMA', 'HUBIKOSI'],
      ),
      IdCity(
        name: 'KABUPATEN PEGUNUNGAN BINTANG',
        districts: ['OKSIBIL', 'IWUR', 'KIWIROK', 'BATOM'],
      ),
      IdCity(
        name: 'KABUPATEN YAHUKIMO',
        districts: ['DEKAI', 'KURIMA', 'ANGGRUK', 'SUMOHAI'],
      ),
      IdCity(
        name: 'KABUPATEN TOLIKARA',
        districts: ['KARUBAGA', 'KANGGIME', 'BOKONDINI', 'KEMBU'],
      ),
    ],
  ),
];
