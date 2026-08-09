import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_form_widgets.dart';
import 'package:jebby/model/provider_onboarding_data.dart';
import 'package:jebby/model/stripe_requirement_fields.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:jebby/view_model/onboarding_controller.dart';
import 'package:jebby/utils/show_snackbar.dart';

class StripeRequirementsModal extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> requirements;
  final String? message;
  final VoidCallback onSubmitted;

  const StripeRequirementsModal({
    super.key,
    required this.userId,
    required this.requirements,
    this.message,
    required this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required Map<String, dynamic> requirements,
    String? message,
    required VoidCallback onSubmitted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => StripeRequirementsModal(
        userId: userId,
        requirements: requirements,
        message: message,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<StripeRequirementsModal> createState() => _StripeRequirementsModalState();
}

class _StripeRequirementsModalState extends State<StripeRequirementsModal> {
  static const Color _subtitleGrey = Color(0xFF72747A);

  final ImagePicker _picker = ImagePicker();
  late final List<String> _dueKeys;
  late final List<StripeFormFieldDef> _fields;
  late final Map<String, dynamic> _values;
  final Map<String, TextEditingController> _controllers = {};

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dueKeys = StripeRequirementFields.collectDueKeys(widget.requirements);
    _fields = StripeRequirementFields.resolveFields(_dueKeys);

    final controller = ensureOnboardingController();
    _values = StripeRequirementFields.seedValuesFromProviderData(
      controller.providerData,
    );

    for (final field in _fields) {
      if (_isTextBackedField(field.kind)) {
        final initial = _initialTextForField(field);
        _controllers[field.id] = TextEditingController(text: initial);
      }
    }
  }

  bool _isTextBackedField(StripeFormFieldKind kind) {
    return kind != StripeFormFieldKind.dateOfBirth &&
        kind != StripeFormFieldKind.state &&
        kind != StripeFormFieldKind.mcc &&
        kind != StripeFormFieldKind.idType &&
        kind != StripeFormFieldKind.idFrontImage &&
        kind != StripeFormFieldKind.idBackImage;
  }

  String _initialTextForField(StripeFormFieldDef field) {
    final value = _values[field.id];
    if (value == null) return '';
    return value.toString();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showSnack(String message) =>
      showAppErrorSnackbar(message, title: 'Required');

  Future<void> _pickIdImage(bool isBack) async {
    final source = await showOnboardingImageSourceSheet(context);
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    setState(() {
      if (isBack) {
        _values['id_back_path'] = file.path;
        _values.remove('id_back_file_id');
      } else {
        _values['id_front_path'] = file.path;
        _values.remove('id_front_file_id');
      }
    });
  }

  bool _validateFields() {
    for (final field in _fields) {
      switch (field.kind) {
        case StripeFormFieldKind.email:
          final email = _controllers[field.id]?.text.trim() ?? '';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
            _showSnack('Please enter a valid email address.');
            return false;
          }
          _values[field.id] = email;
          break;
        case StripeFormFieldKind.phone:
          final phone = _controllers[field.id]?.text.trim() ?? '';
          if (!ProviderOnboardingData.isValidUsPhone(phone)) {
            _showSnack('Please enter a valid US phone number.');
            return false;
          }
          _values[field.id] = phone;
          break;
        case StripeFormFieldKind.ssnLast4:
          final ssn = _controllers[field.id]?.text.trim() ?? '';
          if (!RegExp(r'^\d{4}$').hasMatch(ssn)) {
            _showSnack('Please enter the last 4 digits of your SSN.');
            return false;
          }
          _values[field.id] = ssn;
          break;
        case StripeFormFieldKind.idNumber:
          final ssn = _controllers[field.id]?.text.trim() ?? '';
          if (!RegExp(r'^\d{9}$').hasMatch(ssn)) {
            _showSnack('Please enter your full 9-digit SSN.');
            return false;
          }
          _values[field.id] = ssn;
          break;
        case StripeFormFieldKind.dateOfBirth:
          if (_values['dob'] is! DateTime) {
            _showSnack('Please select your date of birth.');
            return false;
          }
          break;
        case StripeFormFieldKind.state:
          final state = _values['address_state']?.toString() ?? '';
          if (!ProviderOnboardingData.isValidUsStateCode(state)) {
            _showSnack('Please select your state.');
            return false;
          }
          break;
        case StripeFormFieldKind.url:
          final url = _controllers[field.id]?.text.trim() ?? '';
          if (!ProviderOnboardingData.isValidBusinessUrl(url)) {
            _showSnack('Please enter a valid website URL (https://...).');
            return false;
          }
          _values[field.id] = url;
          break;
        case StripeFormFieldKind.bankRouting:
          final routing =
              _controllers[field.id]?.text.replaceAll(RegExp(r'\D'), '') ?? '';
          if (routing.length != 9) {
            _showSnack('Please enter a valid 9-digit routing number.');
            return false;
          }
          _values[field.id] = routing;
          break;
        case StripeFormFieldKind.bankAccount:
          final account =
              _controllers[field.id]?.text.replaceAll(RegExp(r'\D'), '') ?? '';
          if (account.length < 4) {
            _showSnack('Please enter a valid account number.');
            return false;
          }
          _values[field.id] = account;
          break;
        case StripeFormFieldKind.idFrontImage:
          final frontPath = _values['id_front_path']?.toString();
          final frontFileId = _values['id_front_file_id']?.toString();
          if ((frontPath == null || !File(frontPath).existsSync()) &&
              (frontFileId == null || frontFileId.isEmpty)) {
            _showSnack('Please upload the front of your ID.');
            return false;
          }
          break;
        case StripeFormFieldKind.idBackImage:
          final idType = _values['id_type']?.toString() ??
              ProviderIdType.drivingLicense;
          if (!ProviderIdType.requiresBack(idType)) break;
          final backPath = _values['id_back_path']?.toString();
          final backFileId = _values['id_back_file_id']?.toString();
          if ((backPath == null || !File(backPath).existsSync()) &&
              (backFileId == null || backFileId.isEmpty)) {
            _showSnack('Please upload the back of your ID.');
            return false;
          }
          break;
        case StripeFormFieldKind.text:
        case StripeFormFieldKind.bankHolder:
          final text = _controllers[field.id]?.text.trim() ?? '';
          if (text.isEmpty) {
            _showSnack('Please enter ${field.label.toLowerCase()}.');
            return false;
          }
          _values[field.id] = text;
          break;
        case StripeFormFieldKind.mcc:
        case StripeFormFieldKind.idType:
          break;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateFields()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final needsUpload = _fields.any(
        (field) =>
            field.kind == StripeFormFieldKind.idFrontImage ||
            field.kind == StripeFormFieldKind.idBackImage,
      );

      if (needsUpload) {
        final frontPath = _values['id_front_path']?.toString();
        if (frontPath != null &&
            frontPath.isNotEmpty &&
            File(frontPath).existsSync()) {
          final idType = _values['id_type']?.toString() ??
              ProviderIdType.drivingLicense;
          final backPath = _values['id_back_path']?.toString();
          final uploadResponse =
              await ApiRepository.shared.uploadIdentityDocumentFuture(
            userId: widget.userId,
            documentType: idType,
            frontPath: frontPath,
            backPath: ProviderIdType.requiresBack(idType) ? backPath : null,
          );
          _values['id_front_file_id'] =
              uploadResponse['front_file_id']?.toString();
          _values['id_back_file_id'] = uploadResponse['back_file_id']?.toString();
        }
      }

      final body = StripeRequirementFields.buildSubmitBody(
        userId: widget.userId,
        dueKeys: _dueKeys,
        values: _values,
        fieldIds: _fields.map((field) => field.id).toList(),
      );

      final response =
          await ApiRepository.shared.submitProviderRequirementsFuture(
        body: body,
      );

      if (!mounted) return;

      final status = response['status']?.toString() ?? '';
      if (status == 'active' || status == 'pending') {
        Navigator.of(context).pop();
        widget.onSubmitted();
        showAppSuccessSnackbar(
          response['message']?.toString() ??
              'Your information was submitted successfully.',
          title: 'Submitted',
        );
        return;
      }

      if (status == 'requires_info') {
        setState(() {
          _isSubmitting = false;
          _errorMessage = ApiRepository.extractApiErrorMessage(
            response,
            fallback: 'Stripe still needs additional information.',
          );
        });
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = ApiRepository.extractApiErrorMessage(
          response,
          fallback: 'Unable to submit required information.',
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = ApiRepository.extractApiErrorMessage(
          error,
          fallback: error.toString(),
        );
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial =
        _values['dob'] is DateTime ? _values['dob'] as DateTime : DateTime(now.year - 25);
    final picked = await showOnboardingDatePicker(
      context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      setState(() => _values['dob'] = picked);
    }
  }

  String get _dobLabel {
    if (_values['dob'] is! DateTime) return 'Select date of birth';
    return DateFormat.yMMMMd().format(_values['dob'] as DateTime);
  }

  Widget _buildField(StripeFormFieldDef field) {
    switch (field.kind) {
      case StripeFormFieldKind.dateOfBirth:
        return OnboardingDateField(label: _dobLabel, onTap: _pickDob);
      case StripeFormFieldKind.state:
        return OnboardingDropdownField<String>(
          value: (_values['address_state']?.toString().isNotEmpty ?? false)
              ? _values['address_state'].toString()
              : ProviderOnboardingData.usStates.first['code']!,
          items: ProviderOnboardingData.usStates
              .map((state) => state['code']!)
              .toList(),
          labelBuilder: (code) =>
              '${ProviderOnboardingData.stateName(code)} ($code)',
          onChanged: (value) {
            if (value != null) setState(() => _values['address_state'] = value);
          },
        );
      case StripeFormFieldKind.mcc:
        return OnboardingDropdownField<String>(
          value: (_values['business_mcc']?.toString().isNotEmpty ?? false)
              ? _values['business_mcc'].toString()
              : ProviderBusinessDefaults.businessMcc,
          items: ProviderOnboardingData.mccOptions
              .map((option) => option.code)
              .toList(),
          labelBuilder: (code) => ProviderOnboardingData.mccLabel(code),
          onChanged: (value) {
            if (value != null) setState(() => _values['business_mcc'] = value);
          },
        );
      case StripeFormFieldKind.idType:
        return Column(
          children: ProviderIdType.labels.entries.map((entry) {
            return RadioListTile<String>(
              value: entry.key,
              groupValue:
                  _values['id_type']?.toString() ?? ProviderIdType.drivingLicense,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _values['id_type'] = value);
              },
              title: Text(
                entry.value,
                style: GoogleFonts.inter(fontSize: 14),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: darkBlue,
            );
          }).toList(),
        );
      case StripeFormFieldKind.idFrontImage:
      case StripeFormFieldKind.idBackImage:
        final isBack = field.kind == StripeFormFieldKind.idBackImage;
        final pathKey = isBack ? 'id_back_path' : 'id_front_path';
        final path = _values[pathKey]?.toString();
        final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
        return OutlinedButton.icon(
          onPressed: _isSubmitting ? null : () => _pickIdImage(isBack),
          icon: Icon(hasImage ? Icons.check_circle : Icons.upload_outlined),
          label: Text(hasImage ? 'Photo selected' : 'Upload photo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: darkBlue,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      case StripeFormFieldKind.ssnLast4:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: 'Last 4 digits',
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case StripeFormFieldKind.idNumber:
      case StripeFormFieldKind.bankRouting:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: field.hint ?? field.label,
          keyboardType: TextInputType.number,
          maxLength: field.kind == StripeFormFieldKind.idNumber ? 9 : 9,
          obscureText: field.kind == StripeFormFieldKind.idNumber,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case StripeFormFieldKind.bankAccount:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: 'Account number',
          keyboardType: TextInputType.number,
          obscureText: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case StripeFormFieldKind.phone:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: field.hint ?? 'Phone number',
          keyboardType: TextInputType.phone,
        );
      case StripeFormFieldKind.email:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        );
      case StripeFormFieldKind.url:
      case StripeFormFieldKind.text:
      case StripeFormFieldKind.bankHolder:
        return OnboardingTextField(
          controller: _controllers[field.id]!,
          hint: field.hint ?? field.label,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.86;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH, maxWidth: 420),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Required information',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey.shade600, size: 22),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.message != null &&
                          widget.message!.trim().isNotEmpty) ...[
                        Text(
                          widget.message!.trim(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _subtitleGrey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        'Stripe is requesting the following details:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _subtitleGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._dueKeys.map(
                        (key) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: _subtitleGrey)),
                              Expanded(
                                child: Text(
                                  StripeRequirementFields.humanizeStripeKey(key),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF2A2A2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_fields.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Please contact support if you continue to see this message.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _subtitleGrey,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Text(
                          'Complete the fields below',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _subtitleGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._fields.map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OnboardingFieldLabel(field.label),
                                _buildField(field),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            (_isSubmitting || _fields.isEmpty) ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Submit',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
