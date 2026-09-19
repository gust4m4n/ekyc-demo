import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand.dart';

/// Rewrites every edit in upper case so stored values match the document.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}

/// Text field with the label rendered above the box so error text stays
/// directly under the input.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.errorText,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.uppercase = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  /// Set by the screen only for the single field it currently complains
  /// about, so the user is never shown a wall of red text.
  final String? errorText;

  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;

  /// Transforms every keystroke to upper case. Disable for case sensitive
  /// values such as an email address.
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textCapitalization: uppercase
                ? TextCapitalization.characters
                : TextCapitalization.none,
            maxLength: maxLength,
            maxLines: maxLines,
            style: TextStyle(
              color: readOnly ? BrandColors.muted : BrandColors.primaryDark,
            ),
            inputFormatters: [
              if (uppercase) const UpperCaseTextFormatter(),
              ...?inputFormatters,
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              counterText: '',
              fillColor: readOnly ? BrandColors.readOnlyFill : null,
              suffixIcon: readOnly
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: BrandColors.muted,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown over any value type; [itemLabel] keeps enums out of the UI layer.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
    this.errorText,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabel;
  final String? errorText;
  final String? hint;
  final bool enabled;

  String _labelOf(T item) => itemLabel?.call(item) ?? '$item';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: items.contains(value) ? value : null,
            isExpanded: true,
            menuMaxHeight: 360,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: BrandColors.surface,
            icon: const Icon(
              Icons.expand_more_rounded,
              color: BrandColors.muted,
            ),
            hint: Text(
              hint ?? 'Select $label',
              style: const TextStyle(color: BrandColors.muted),
            ),
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  child: Text(_labelOf(item), overflow: TextOverflow.ellipsis),
                ),
            ],
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              errorText: errorText,
              fillColor: enabled ? null : BrandColors.readOnlyFill,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only field that opens a date picker.
class LabeledDateField extends StatelessWidget {
  const LabeledDateField({
    super.key,
    required this.label,
    required this.value,
    required this.displayText,
    required this.onPick,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final String displayText;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onPick();
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: errorText,
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: BrandColors.muted,
                ),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 16,
                  color: value == null
                      ? BrandColors.muted
                      : BrandColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: BrandColors.primaryDark,
      ),
    );
  }
}
