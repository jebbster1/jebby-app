import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_form_widgets.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/Views/screens/onboarding/verify_identity_screen.dart';
import 'package:jebby/model/provider_onboarding_data.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/view_model/onboarding_controller.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final bool returnToReview;

  const PersonalDetailsScreen({
    super.key,
    this.returnToReview = false,
  });

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final OnboardingController _controller = ensureOnboardingController();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ssnController;
  late final TextEditingController _addressSearchController;
  ParsedUsAddress? _resolvedAddress;
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    if (!widget.returnToReview) {
      _controller.advanceTo(6);
    }
    final data = _controller.providerData;
    _firstNameController = TextEditingController(text: data.firstName);
    _lastNameController = TextEditingController(text: data.lastName);
    _emailController = TextEditingController(text: data.email);
    _phoneController = TextEditingController(text: data.phone);
    _ssnController = TextEditingController(text: data.ssnLast4 ?? '');
    _resolvedAddress = ParsedUsAddress.fromStored(
      line1: data.addressLine1,
      city: data.addressCity,
      state: data.addressState,
      postalCode: data.addressPostalCode,
    );
    _addressSearchController = TextEditingController(
      text: _resolvedAddress!.isComplete
          ? _resolvedAddress!.displaySummary
          : data.addressLine1,
    );
    _selectedDob = data.dateOfBirth;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ssnController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  String get _dobLabel {
    if (_selectedDob == null) return 'Select date of birth';
    return DateFormat.yMMMMd().format(_selectedDob!);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showOnboardingDatePicker(
      context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim());
  }

  void _showError(String message) {
    Get.snackbar(
      'Missing information',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  void _clearResolvedAddress() {
    setState(() => _resolvedAddress = const ParsedUsAddress());
  }

  Future<void> _onAddressResolved(ParsedUsAddress parsed) async {
    if (parsed.isComplete) {
      setState(() {
        _resolvedAddress = parsed;
        _addressSearchController.text = parsed.displaySummary;
      });
      return;
    }

    final completed = await showOnboardingMissingAddressDialog(
      context,
      initial: parsed,
    );
    if (!mounted) return;

    if (completed == null) {
      _clearResolvedAddress();
      return;
    }

    setState(() {
      _resolvedAddress = completed;
      _addressSearchController.text = completed.displaySummary;
    });
  }

  Future<bool> _ensureCompleteAddress() async {
    var address = _resolvedAddress ?? const ParsedUsAddress();
    if (address.isComplete) return true;

    if (address.line1.isEmpty &&
        address.city.isEmpty &&
        address.state.isEmpty &&
        address.postalCode.isEmpty) {
      _showError('Please search for and select your home address.');
      return false;
    }

    final completed = await showOnboardingMissingAddressDialog(
      context,
      initial: address,
    );
    if (!mounted || completed == null) return false;

    setState(() {
      _resolvedAddress = completed;
      _addressSearchController.text = completed.displaySummary;
    });
    return completed.isComplete;
  }

  Future<void> _continue() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final ssn = _ssnController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showError('Please enter your first and last name.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (_selectedDob == null) {
      _showError('Please select your date of birth.');
      return;
    }
    final ageCutoff = DateTime(
      DateTime.now().year - 18,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (_selectedDob!.isAfter(ageCutoff)) {
      _showError('You must be at least 18 years old.');
      return;
    }
    if (!ProviderOnboardingData.isValidUsPhone(phone)) {
      _showError('Please enter a valid US phone number (10 digits, real area code).');
      return;
    }

    final e164Phone = ProviderOnboardingData.formatPhoneE164(phone);
    if (ssn.length != 4 || !RegExp(r'^\d{4}$').hasMatch(ssn)) {
      _showError('Please enter the last 4 digits of your SSN.');
      return;
    }

    if (!await _ensureCompleteAddress()) return;

    final address = _resolvedAddress!;
    await _controller.updateProviderData(
      _controller.providerData.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: e164Phone,
        dobDay: _selectedDob!.day,
        dobMonth: _selectedDob!.month,
        dobYear: _selectedDob!.year,
        ssnLast4: ssn,
        addressLine1: address.line1,
        addressCity: address.city,
        addressState: address.state.toUpperCase(),
        addressPostalCode: address.postalCode.replaceAll(RegExp(r'\D'), ''),
        businessUrl: ProviderBusinessDefaults.businessUrl,
        businessMcc: ProviderBusinessDefaults.businessMcc,
        accountHolderName:
            _controller.providerData.accountHolderName.isNotEmpty
                ? _controller.providerData.accountHolderName
                : '$firstName $lastName',
      ),
    );

    if (widget.returnToReview) {
      await _controller.advanceTo(9);
      Get.back();
      return;
    }

    await _controller.advanceTo(7);
    Get.to(() => const VerifyIdentityScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 6,
      title: 'Personal Details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingSectionTitle(
            'Tell us about yourself',
            subtitle:
                'This information is required to verify your identity and set up payouts.',
          ),
          const OnboardingFieldLabel('First name'),
          OnboardingTextField(
            controller: _firstNameController,
            hint: 'First name',
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Last name'),
          OnboardingTextField(
            controller: _lastNameController,
            hint: 'Last name',
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Email'),
          OnboardingTextField(
            controller: _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Date of birth'),
          OnboardingDateField(label: _dobLabel, onTap: _pickDob),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Phone number'),
          OnboardingTextField(
            controller: _phoneController,
            hint: '+1 (555) 555-5555',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('SSN last 4 digits'),
          OnboardingTextField(
            controller: _ssnController,
            hint: '1234',
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          Text(
            'Required for US identity verification with Stripe.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          Text(
            'Home address',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const OnboardingFieldLabel('Address'),
          OnboardingAddressAutocompleteField(
            controller: _addressSearchController,
            resolvedAddress: _resolvedAddress,
            onAddressResolved: _onAddressResolved,
            onEditingStarted: _clearResolvedAddress,
          ),
          const SizedBox(height: 8),
          Text(
            'Search for your address, then confirm the details Google provides.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 24),
          const OnboardingStripeFooter(),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: widget.returnToReview ? 'Save' : 'Continue',
          onPressed: _continue,
        ),
      ),
    );
  }
}
