import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/country_profile.dart';
import '../config/indonesia_regions.dart';
import '../models/ekyc_draft.dart';
import '../state/ekyc_controller.dart';
import '../utils/validators.dart';
import '../widgets/form_fields.dart';
import '../widgets/step_scaffold.dart';
import 'document_screen.dart';

/// Step 3 — registered address.
///
/// The street line is free text; province, city and district are dependent
/// dropdowns where each level only appears once its parent has been picked.
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, this.returnToReview = false});

  final bool returnToReview;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _street = TextEditingController();
  final _postalCode = TextEditingController();

  late CountryProfile _country;
  IdProvince? _province;
  IdCity? _city;
  String? _district;

  /// Key of the one field whose message is currently visible.
  String? _errorField;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final draft = EKycScope.read(context);
    _country = draft.country;

    final existing = draft.address;
    if (existing != null) {
      _street.text = existing.street;
      _postalCode.text = existing.postalCode;
      _province = provinceByName(existing.province);
      _city = cityByName(_province, existing.city);
      _district = (_city?.districts.contains(existing.district) ?? false)
          ? existing.district
          : null;
    }

    _street.addListener(_clearErrorWhenFixed);
    _postalCode.addListener(_clearErrorWhenFixed);
  }

  @override
  void dispose() {
    _street.removeListener(_clearErrorWhenFixed);
    _postalCode.removeListener(_clearErrorWhenFixed);
    _street.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  /// Ordered top to bottom so the user is walked down the form.
  List<FieldCheck> get _checks => [
    FieldCheck(
      'street',
      () => validateLength(_street.text, 'Address', min: 5, max: 200),
    ),
    FieldCheck(
      'province',
      () => validateRequiredChoice(_province?.name, 'province'),
    ),
    FieldCheck(
      'city',
      () => validateRequiredChoice(_city?.name, 'city or regency'),
    ),
    FieldCheck('district', () => validateRequiredChoice(_district, 'district')),
    FieldCheck(
      'postalCode',
      () => validatePostalCode(
        _postalCode.text,
        _country.postalCodeRule,
        _country.postalCodeLabel,
      ),
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

  void _submit() {
    if (_showFirstError()) return;

    EKycScope.read(context).setAddress(
      AddressData(
        street: _street.text.trim(),
        province: _province!.name,
        city: _city!.name,
        district: _district!,
        postalCode: _country.hasPostalCode
            ? _postalCode.text.trim().toUpperCase()
            : '',
        countryCode: _country.code,
      ),
    );

    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DocumentScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final postalRule = _country.postalCodeRule;
    final province = _province;
    final city = _city;

    return StepScaffold(
      step: 3,
      title: 'Address',
      actions: ElevatedButton(
        onPressed: _submit,
        child: Text(widget.returnToReview ? 'Save changes' : 'Continue'),
      ),
      child: ListView(
        children: [
          const SectionTitle(
            'Registered address',
            subtitle:
                'Enter the address exactly as it appears on your identity '
                'document.',
          ),
          const SizedBox(height: 20),
          LabeledTextField(
            label: 'Address',
            controller: _street,
            hint: 'Enter street and house number',
            maxLines: 3,
            maxLength: 200,
            errorText: _errorFor('street'),
          ),
          LabeledDropdown<IdProvince>(
            label: 'Province',
            value: province,
            items: kIndonesiaProvinces,
            itemLabel: (item) => item.name,
            hint: 'Select province',
            errorText: _errorFor('province'),
            onChanged: (value) {
              setState(() {
                _province = value;
                _city = null;
                _district = null;
              });
              _clearErrorWhenFixed();
            },
          ),
          if (province != null)
            LabeledDropdown<IdCity>(
              key: ValueKey('city-${province.name}'),
              label: 'City or regency',
              value: city,
              items: province.cities,
              itemLabel: (item) => item.name,
              hint: 'Select city or regency',
              errorText: _errorFor('city'),
              onChanged: (value) {
                setState(() {
                  _city = value;
                  _district = null;
                });
                _clearErrorWhenFixed();
              },
            ),
          if (city != null)
            LabeledDropdown<String>(
              key: ValueKey('district-${city.name}'),
              label: 'District',
              value: _district,
              items: city.districts,
              hint: 'Select district',
              errorText: _errorFor('district'),
              onChanged: (value) {
                setState(() => _district = value);
                _clearErrorWhenFixed();
              },
            ),
          if (postalRule != null)
            LabeledTextField(
              label: _country.postalCodeLabel,
              controller: _postalCode,
              hint: 'Enter ${postalRule.requirement}',
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              maxLength: postalRule.maxLength,
              inputFormatters: [
                if (postalRule.digitsOnly)
                  FilteringTextInputFormatter.digitsOnly,
              ],
              errorText: _errorFor('postalCode'),
            ),
        ],
      ),
    );
  }
}
