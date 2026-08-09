import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/widgets/address_autocomplete_field.dart';
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

class OnboardingAddressAutocompleteField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AddressAutocompleteField(
      controller: controller,
      resolvedAddress: resolvedAddress,
      onEditingStarted: onEditingStarted,
      onAddressSelected: onAddressResolved,
      hint: 'Start typing your address',
      decoration: InputDecoration(
        hintText: 'Start typing your address',
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF8F9098),
        ),
        filled: true,
        fillColor: _fieldFill,
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

Future<ParsedUsAddress?> showOnboardingMissingAddressDialog(
  BuildContext context, {
  required ParsedUsAddress initial,
}) =>
    showMissingAddressDialog(context, initial: initial);

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
