import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/model/provider_onboarding_data.dart';
import 'package:jebby/utils/google_places_address.dart';

const Color _fieldFill = Color(0xFFF7F7F9);

class OnboardingFieldLabel extends StatelessWidget {
  final String text;

  const OnboardingFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const OnboardingTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLength,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1B1B1F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF8F9098),
        ),
        counterText: maxLength != null ? null : '',
        filled: true,
        fillColor: _fieldFill,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBlue, width: 1.5),
        ),
      ),
    );
  }
}

class OnboardingDateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OnboardingDateField({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: label.startsWith('Select')
                      ? const Color(0xFF8F9098)
                      : const Color(0xFF1B1B1F),
                ),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class OnboardingDropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const OnboardingDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value) ? value : null;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: effectiveValue,
          isExpanded: true,
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF8F9098),
                  ),
                ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: onChanged == null
                ? const Color(0xFFBDBEC6)
                : const Color(0xFF8F9098),
          ),
          onChanged: onChanged,
          style: GoogleFonts.inter(
            color: const Color(0xFF1B1B1F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class OnboardingSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const OnboardingSectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

Future<DateTime?> showOnboardingDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Select date of birth',
    cancelText: 'Cancel',
    confirmText: 'OK',
    builder: (context, child) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: ColorScheme.light(
            primary: darkBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
            surfaceTint: Colors.transparent,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor: lightBlue,
            headerForegroundColor: Colors.black87,
            weekdayStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            dayStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            yearStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) return Colors.black26;
              return Colors.black87;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return darkBlue;
              return Colors.transparent;
            }),
            todayForegroundColor: WidgetStateProperty.all(darkBlue),
            todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Colors.black87;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return darkBlue;
              return Colors.transparent;
            }),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: darkBlue,
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

class OnboardingAddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final ParsedUsAddress? resolvedAddress;
  final Future<void> Function(ParsedUsAddress) onAddressResolved;
  final VoidCallback? onEditingStarted;

  const OnboardingAddressAutocompleteField({
    super.key,
    required this.controller,
    required this.resolvedAddress,
    required this.onAddressResolved,
    this.onEditingStarted,
  });

  @override
  State<OnboardingAddressAutocompleteField> createState() =>
      _OnboardingAddressAutocompleteFieldState();
}

class _OnboardingAddressAutocompleteFieldState
    extends State<OnboardingAddressAutocompleteField> {
  final GooglePlacesAddressService _placesService = GooglePlacesAddressService();
  List<Map<String, dynamic>> _predictions = [];
  bool _loadingDetails = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _onQueryChanged(String value) {
    widget.onEditingStarted?.call();
    _fetchPredictions(value);
  }

  Future<void> _fetchPredictions(String input) async {
    if (input.trim().length < 3) {
      if (mounted) setState(() => _predictions = []);
      return;
    }

    try {
      final results = await _placesService.fetchPredictions(input);
      if (mounted) setState(() => _predictions = results.take(5).toList());
    } catch (_) {
      if (mounted) setState(() => _predictions = []);
    }
  }

  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    final description = prediction['description']?.toString() ?? '';
    final placeId = prediction['place_id']?.toString() ?? '';
    if (placeId.isEmpty) return;

    setState(() {
      _loadingDetails = true;
      _predictions = [];
    });
    widget.controller.text = description;

    try {
      final parsed = await _placesService.resolvePlace(placeId);
      if (!mounted) return;
      if (parsed != null) {
        await widget.onAddressResolved(parsed);
      }
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolvedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingTextField(
          controller: widget.controller,
          hint: 'Start typing your address',
          onChanged: _onQueryChanged,
          suffix: _loadingDetails
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                final description = prediction['description']?.toString() ?? '';
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place_outlined, color: darkBlue, size: 20),
                  title: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () => _selectPrediction(prediction),
                );
              },
            ),
          ),
        if (resolved != null && resolved.isComplete) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF6EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB8D4B8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resolved.displaySummary,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Future<ParsedUsAddress?> showOnboardingMissingAddressDialog(
  BuildContext context, {
  required ParsedUsAddress initial,
}) {
  return showDialog<ParsedUsAddress>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _MissingAddressDialog(initial: initial),
  );
}

class _MissingAddressDialog extends StatefulWidget {
  final ParsedUsAddress initial;

  const _MissingAddressDialog({required this.initial});

  @override
  State<_MissingAddressDialog> createState() => _MissingAddressDialogState();
}

class _MissingAddressDialogState extends State<_MissingAddressDialog> {
  late final TextEditingController _line1Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late String _stateCode;

  ParsedUsAddress get initial => widget.initial;

  @override
  void initState() {
    super.initState();
    _line1Controller = TextEditingController(text: initial.line1);
    _cityController = TextEditingController(text: initial.city);
    _postalController = TextEditingController(text: initial.postalCode);
    _stateCode = initial.state.toUpperCase();
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = ParsedUsAddress(
      line1: initial.hasLine1 ? initial.line1 : _line1Controller.text.trim(),
      city: initial.hasCity ? initial.city : _cityController.text.trim(),
      state: initial.hasState ? initial.state : _stateCode.toUpperCase(),
      postalCode: initial.hasPostalCode
          ? initial.postalCode
          : _postalController.text.trim(),
    );
    if (!updated.isComplete) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Complete your address',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We could not read every part of that address. Please fill in the missing details.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (!initial.hasLine1) ...[
              const OnboardingFieldLabel('Street address'),
              OnboardingTextField(
                controller: _line1Controller,
                hint: '123 Main St',
              ),
              const SizedBox(height: 12),
            ],
            if (!initial.hasCity) ...[
              const OnboardingFieldLabel('City'),
              OnboardingTextField(
                controller: _cityController,
                hint: 'City',
              ),
              const SizedBox(height: 12),
            ],
            if (!initial.hasState) ...[
              const OnboardingFieldLabel('State'),
              OnboardingDropdownField<String>(
                value: _stateCode,
                items: ProviderOnboardingData.usStates
                    .map((state) => state['code']!)
                    .toList(),
                hint: 'Select state',
                labelBuilder: (code) => ProviderOnboardingData.stateName(code),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _stateCode = value);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (!initial.hasPostalCode) ...[
              const OnboardingFieldLabel('ZIP code'),
              OnboardingTextField(
                controller: _postalController,
                hint: '94102',
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            'Save',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: darkBlue,
            ),
          ),
        ),
      ],
    );
  }
}

Future<ImageSource?> showOnboardingImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload ID photo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: darkBlue),
              title: Text(
                'Choose from gallery',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: darkBlue),
              title: Text(
                'Take a photo',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
