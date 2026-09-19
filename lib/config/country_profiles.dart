import 'country_profile.dart';

/// Markets the demo ships with.
///
/// The set is deliberately mixed so every branch of the address form is
/// exercised: countries with and without a national ID, with dropdown or free
/// text administrative areas, and with or without postal codes.
const List<CountryProfile> kCountryProfiles = [
  _indonesia,
  _malaysia,
  _singapore,
  _philippines,
  _india,
  _unitedArabEmirates,
  _unitedKingdom,
  _unitedStates,
];

const CountryProfile kDefaultCountryProfile = _indonesia;

/// Markets the user may actually pick. The demo is limited to Indonesia.
const List<CountryProfile> kSelectableCountryProfiles = [_indonesia];

/// The only nationality the demo accepts.
const String kFixedNationality = 'INDONESIA';

CountryProfile countryProfileOf(String code) => kCountryProfiles.firstWhere(
  (profile) => profile.code == code,
  orElse: () => kDefaultCountryProfile,
);

const _indonesia = CountryProfile(
  code: 'ID',
  name: 'Indonesia',
  dialCode: '+62',
  minimumAge: 17,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.drivingLicence,
  ],
  nationalIdLabel: 'National ID number (NIK)',
  nationalIdRule: PatternRule(
    pattern: r'^\d{16}$',
    requirement: 'exactly 16 digits',
    example: '3201010101990001',
    maxLength: 16,
    digitsOnly: true,
  ),
  nationalIdHasExpiry: false,
  localityLabel: 'City / regency',
  administrativeAreaLabel: 'Province',
  // Provinces, cities and districts come from `indonesia_regions.dart`.
  postalCodeRule: PatternRule(
    pattern: r'^\d{5}$',
    requirement: '5 digits',
    example: '40115',
    maxLength: 5,
    digitsOnly: true,
  ),
  addressExample: 'Jl. Merdeka No. 12',
);

const _malaysia = CountryProfile(
  code: 'MY',
  name: 'Malaysia',
  dialCode: '+60',
  minimumAge: 18,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.drivingLicence,
  ],
  nationalIdLabel: 'MyKad number',
  nationalIdRule: PatternRule(
    pattern: r'^\d{12}$',
    requirement: 'exactly 12 digits',
    example: '900101015432',
    maxLength: 12,
    digitsOnly: true,
  ),
  nationalIdHasExpiry: false,
  localityLabel: 'City / town',
  administrativeAreaLabel: 'State',
  administrativeAreas: [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Malacca',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ],
  postalCodeRule: PatternRule(
    pattern: r'^\d{5}$',
    requirement: '5 digits',
    example: '50480',
    maxLength: 5,
    digitsOnly: true,
  ),
  addressExample: '12 Jalan Ampang',
);

const _singapore = CountryProfile(
  code: 'SG',
  name: 'Singapore',
  dialCode: '+65',
  minimumAge: 18,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.residencePermit,
  ],
  nationalIdLabel: 'NRIC / FIN',
  nationalIdRule: PatternRule(
    pattern: r'^[STFGM]\d{7}[A-Z]$',
    requirement: 'a letter, 7 digits and a checksum letter',
    example: 'S1234567D',
    maxLength: 9,
  ),
  nationalIdHasExpiry: false,
  localityLabel: 'City',
  postalCodeRule: PatternRule(
    pattern: r'^\d{6}$',
    requirement: '6 digits',
    example: '238859',
    maxLength: 6,
    digitsOnly: true,
  ),
  addressExample: '1 Orchard Road, #12-34',
);

const _philippines = CountryProfile(
  code: 'PH',
  name: 'Philippines',
  dialCode: '+63',
  minimumAge: 18,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.drivingLicence,
  ],
  nationalIdLabel: 'PhilSys number (PSN)',
  nationalIdRule: PatternRule(
    pattern: r'^\d{12}$',
    requirement: 'exactly 12 digits',
    example: '123456789012',
    maxLength: 12,
    digitsOnly: true,
  ),
  nationalIdHasExpiry: false,
  localityLabel: 'City / municipality',
  administrativeAreaLabel: 'Region',
  administrativeAreas: [
    'National Capital Region',
    'Cordillera Administrative Region',
    'Region I – Ilocos',
    'Region II – Cagayan Valley',
    'Region III – Central Luzon',
    'Region IV-A – CALABARZON',
    'Region IV-B – MIMAROPA',
    'Region V – Bicol',
    'Region VI – Western Visayas',
    'Region VII – Central Visayas',
    'Region VIII – Eastern Visayas',
    'Region IX – Zamboanga Peninsula',
    'Region X – Northern Mindanao',
    'Region XI – Davao',
    'Region XII – SOCCSKSARGEN',
    'Region XIII – Caraga',
    'Bangsamoro (BARMM)',
  ],
  postalCodeRule: PatternRule(
    pattern: r'^\d{4}$',
    requirement: '4 digits',
    example: '1226',
    maxLength: 4,
    digitsOnly: true,
  ),
  addressExample: '12 Ayala Avenue, Unit 5B',
);

const _india = CountryProfile(
  code: 'IN',
  name: 'India',
  dialCode: '+91',
  minimumAge: 18,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.drivingLicence,
  ],
  nationalIdLabel: 'Aadhaar number',
  nationalIdRule: PatternRule(
    pattern: r'^\d{12}$',
    requirement: 'exactly 12 digits',
    example: '123456789012',
    maxLength: 12,
    digitsOnly: true,
  ),
  nationalIdHasExpiry: false,
  localityLabel: 'City / town',
  // Left as free text to show the form working without a reference list.
  administrativeAreaLabel: 'State / union territory',
  postalCodeLabel: 'PIN code',
  postalCodeRule: PatternRule(
    pattern: r'^\d{6}$',
    requirement: '6 digits',
    example: '560001',
    maxLength: 6,
    digitsOnly: true,
  ),
  addressExample: '12 MG Road, Flat 4',
);

const _unitedArabEmirates = CountryProfile(
  code: 'AE',
  name: 'United Arab Emirates',
  dialCode: '+971',
  minimumAge: 18,
  acceptedDocuments: [
    DocumentType.nationalId,
    DocumentType.passport,
    DocumentType.residencePermit,
  ],
  nationalIdLabel: 'Emirates ID',
  nationalIdRule: PatternRule(
    pattern: r'^784\d{12}$',
    requirement: '15 digits starting with 784',
    example: '784199012345671',
    maxLength: 15,
    digitsOnly: true,
  ),
  localityLabel: 'City',
  administrativeAreaLabel: 'Emirate',
  administrativeAreas: [
    'Abu Dhabi',
    'Ajman',
    'Dubai',
    'Fujairah',
    'Ras Al Khaimah',
    'Sharjah',
    'Umm Al Quwain',
  ],
  // The UAE has no postal code system, so the field is hidden entirely.
  addressExample: 'Villa 12, Al Wasl Road',
);

const _unitedKingdom = CountryProfile(
  code: 'GB',
  name: 'United Kingdom',
  dialCode: '+44',
  minimumAge: 18,
  // No national ID card is issued in the UK.
  acceptedDocuments: [
    DocumentType.passport,
    DocumentType.drivingLicence,
    DocumentType.residencePermit,
  ],
  localityLabel: 'Town / city',
  administrativeAreaLabel: 'County',
  administrativeAreaRequired: false,
  postalCodeLabel: 'Postcode',
  postalCodeRule: PatternRule(
    pattern: r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$',
    requirement: 'a valid UK postcode',
    example: 'SW1A 1AA',
    maxLength: 8,
  ),
  addressExample: '221B Baker Street',
);

const _unitedStates = CountryProfile(
  code: 'US',
  name: 'United States',
  dialCode: '+1',
  minimumAge: 18,
  // No federal ID card; a state licence or a passport is used instead.
  acceptedDocuments: [DocumentType.drivingLicence, DocumentType.passport],
  localityLabel: 'City',
  administrativeAreaLabel: 'State',
  administrativeAreas: [
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'District of Columbia',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
  ],
  postalCodeLabel: 'ZIP code',
  postalCodeRule: PatternRule(
    pattern: r'^\d{5}(-\d{4})?$',
    requirement: '5 digits, optionally followed by -4 digits',
    example: '94105',
    maxLength: 10,
  ),
  addressExample: '1600 Market Street, Apt 8',
);
