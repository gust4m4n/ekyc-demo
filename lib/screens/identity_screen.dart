import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/country_profile.dart';
import '../config/country_profiles.dart';
import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../utils/validators.dart';
import '../widgets/form_fields.dart';
import '../widgets/step_scaffold.dart';
import 'address_screen.dart';

/// Step 2 — identity details, rendered from the active [CountryProfile].
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key, this.returnToReview = false});

  /// When true the screen saves and pops back to the summary instead of
  /// continuing to the next step.
  final bool returnToReview;

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final _documentNumber = TextEditingController();
  final _givenNames = TextEditingController();
  final _familyName = TextEditingController();
  final _birthPlace = TextEditingController();
  final _occupation = TextEditingController();
  final _nationality = TextEditingController(text: kFixedNationality);

  late CountryProfile _country;
  late DocumentType _documentType;
  DateTime? _birthDate;
  DateTime? _documentExpiry;

  /// Key of the one field whose message is currently visible.
  String? _errorField;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final draft = EKycScope.read(context);
    _country = draft.country;
    _documentType = _country.defaultDocument;

    final existing = draft.identity;
    if (existing != null) {
      _documentType = existing.documentType;
      _documentNumber.text = existing.documentNumber;
      _givenNames.text = existing.givenNames;
      _familyName.text = existing.familyName;
      _birthPlace.text = existing.birthPlace;
      _occupation.text = existing.occupation;
      _birthDate = existing.birthDate;
      _documentExpiry = existing.documentExpiry;
    }

    for (final controller in _editableControllers) {
      controller.addListener(_clearErrorWhenFixed);
    }
  }

  List<TextEditingController> get _editableControllers => [
    _documentNumber,
    _givenNames,
    _familyName,
    _birthPlace,
    _occupation,
  ];

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_clearErrorWhenFixed);
      controller.dispose();
    }
    _nationality.dispose();
    super.dispose();
  }

  PatternRule get _numberRule => _country.documentNumberRule(_documentType);

  String get _numberLabel => _country.documentNumberLabel(_documentType);

  bool get _expiryRequired => _country.documentExpires(_documentType);

  /// Ordered top to bottom so the user is walked down the form.
  List<FieldCheck> get _checks => [
    FieldCheck(
      'number',
      () => validateDocumentNumber(
        _documentNumber.text,
        _numberRule,
        _numberLabel,
      ),
    ),
    FieldCheck(
      'expiry',
      () => validateExpiryDate(_documentExpiry, required: _expiryRequired),
    ),
    FieldCheck(
      'givenNames',
      () => validateName(_givenNames.text, 'Given names', min: 2, max: 70),
    ),
    FieldCheck(
      'familyName',
      () => validateName(_familyName.text, 'Family name', min: 1, max: 70),
    ),
    FieldCheck(
      'birthDate',
      () => validateBirthDate(_birthDate, minimumAge: _country.minimumAge),
    ),
    FieldCheck(
      'birthPlace',
      () => validateLength(_birthPlace.text, 'Place of birth', min: 2, max: 60),
    ),
    FieldCheck(
      'occupation',
      () => validateLength(_occupation.text, 'Occupation', min: 2, max: 80),
    ),
  ];

  /// Re-runs only the rule that is currently complaining, so fixing a field
  /// hides its message without immediately revealing the next one.
  void _clearErrorWhenFixed() {
    final field = _errorField;
    if (field == null) return;
    final check = _checks.firstWhere((item) => item.field == field);
    if (check.run() != null) return;
    setState(() {
      _errorField = null;
      _errorText = null;
    });
  }

  /// Reveals the first unsatisfied rule and nothing else.
  bool _showFirstError() {
    for (final check in _checks) {
      final error = check.run();
      if (error != null) {
        setState(() {
          _errorField = check.field;
          _errorText = error;
        });
        return true;
      }
    }
    setState(() {
      _errorField = null;
      _errorText = null;
    });
    return false;
  }

  String? _errorFor(String field) => _errorField == field ? _errorText : null;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
    _clearErrorWhenFixed();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _documentExpiry ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      helpText: 'Select the document expiry date',
    );
    if (picked == null) return;
    setState(() => _documentExpiry = picked);
    _clearErrorWhenFixed();
  }

  void _submit() {
    if (_showFirstError()) return;

    EKycScope.read(context).setIdentity(
      IdentityData(
        documentType: _documentType,
        documentNumber: _documentNumber.text.trim().toUpperCase(),
        issuingCountry: _country.code,
        givenNames: _givenNames.text.trim(),
        familyName: _familyName.text.trim(),
        birthDate: _birthDate!,
        birthPlace: _birthPlace.text.trim(),
        nationality: kFixedNationality,
        occupation: _occupation.text.trim(),
        documentExpiry: _expiryRequired ? _documentExpiry : null,
      ),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddressScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final rule = _numberRule;

    return StepScaffold(
      step: 2,
      title: 'Identity details',
      actions: ElevatedButton(
        onPressed: _submit,
        child: Text(widget.returnToReview ? 'Save changes' : 'Continue'),
      ),
      child: ListView(
        children: [
          SectionTitle(
            'Enter the details exactly as printed',
            subtitle:
                'Every field must match your ${_documentType.label.toLowerCase()} '
                'issued in ${_country.name}.',
          ),
          const SizedBox(height: 20),
          if (_country.acceptedDocuments.length > 1)
            LabeledDropdown<DocumentType>(
              label: 'Document type',
              value: _documentType,
              items: _country.acceptedDocuments,
              itemLabel: (type) => type.label,
              hint: 'Select document type',
              onChanged: (type) {
                if (type == null) return;
                setState(() {
                  _documentType = type;
                  _documentNumber.clear();
                  _documentExpiry = null;
                  _errorField = null;
                  _errorText = null;
                });
              },
            ),
          LabeledTextField(
            label: _numberLabel,
            controller: _documentNumber,
            hint: 'Enter ${rule.requirement}',
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            maxLength: rule.maxLength,
            inputFormatters: [
              if (rule.digitsOnly) FilteringTextInputFormatter.digitsOnly,
            ],
            errorText: _errorFor('number'),
          ),
          if (_expiryRequired)
            LabeledDateField(
              label: 'Document expiry date',
              value: _documentExpiry,
              displayText: _documentExpiry == null
                  ? 'Select expiry date'
                  : formatDate(_documentExpiry!),
              onPick: _pickExpiryDate,
              errorText: _errorFor('expiry'),
            ),
          LabeledTextField(
            label: 'Given names',
            controller: _givenNames,
            hint: 'Enter your given names',
            maxLength: 70,
            errorText: _errorFor('givenNames'),
          ),
          LabeledTextField(
            label: 'Family name',
            controller: _familyName,
            hint: 'Enter your surname',
            maxLength: 70,
            errorText: _errorFor('familyName'),
          ),
          LabeledDateField(
            label: 'Date of birth',
            value: _birthDate,
            displayText: _birthDate == null
                ? 'Select date of birth'
                : formatDate(_birthDate!),
            onPick: _pickBirthDate,
            errorText: _errorFor('birthDate'),
          ),
          LabeledTextField(
            label: 'Place of birth',
            controller: _birthPlace,
            hint: 'Enter your city of birth',
            maxLength: 60,
            errorText: _errorFor('birthPlace'),
          ),
          LabeledTextField(
            label: 'Nationality',
            controller: _nationality,
            readOnly: true,
          ),
          LabeledTextField(
            label: 'Occupation',
            controller: _occupation,
            hint: 'Enter your occupation',
            maxLength: 80,
            errorText: _errorFor('occupation'),
          ),
          InfoBanner(
            message:
                'You must be at least ${_country.minimumAge} years old to '
                'complete verification in ${_country.name}.',
          ),
        ],
      ),
    );
  }
}
