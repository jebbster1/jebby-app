import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_form_widgets.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/Views/screens/onboarding/review_submit_screen.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/view_model/onboarding_controller.dart';

class BankAccountScreen extends StatefulWidget {
  final bool returnToReview;

  const BankAccountScreen({
    super.key,
    this.returnToReview = false,
  });

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  late final OnboardingController _controller = ensureOnboardingController();
  late final TextEditingController _holderController;
  late final TextEditingController _routingController;
  late final TextEditingController _accountController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    if (!widget.returnToReview) {
      _controller.advanceTo(8);
    }
    final data = _controller.providerData;
    _holderController = TextEditingController(
      text: data.accountHolderName.isNotEmpty
          ? data.accountHolderName
          : data.legalFullName,
    );
    _routingController = TextEditingController(text: data.routingNumber);
    _accountController = TextEditingController(text: data.accountNumber);
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) =>
      showAppErrorSnackbar(message, title: 'Required');

  Future<void> _continue() async {
    final holder = _holderController.text.trim();
    final routing = _routingController.text.trim();
    final account = _accountController.text.trim();
    final confirm = _confirmController.text.trim();

    if (holder.isEmpty) {
      _showError('Please enter the account holder name.');
      return;
    }
    if (!RegExp(r'^\d{9}$').hasMatch(routing)) {
      _showError('Routing number must be 9 digits.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(account) || account.length < 4) {
      _showError('Please enter a valid account number.');
      return;
    }
    if (account != confirm) {
      _showError('Account numbers do not match.');
      return;
    }

    await _controller.updateProviderData(
      _controller.providerData.copyWith(
        accountHolderName: holder,
        routingNumber: routing,
        accountNumber: account,
      ),
    );

    if (widget.returnToReview) {
      await _controller.advanceTo(9);
      Get.back();
      return;
    }

    await _controller.advanceTo(9);
    Get.to(() => const ReviewSubmitScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 8,
      title: 'Bank Account',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingSectionTitle(
            'Add your payout account',
            subtitle:
                'Payouts are sent directly to your US bank account through Stripe.',
          ),
          const OnboardingFieldLabel('Account holder name'),
          OnboardingTextField(
            controller: _holderController,
            hint: 'Name on bank account',
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Routing number'),
          OnboardingTextField(
            controller: _routingController,
            hint: '9-digit routing number',
            keyboardType: TextInputType.number,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Account number'),
          OnboardingTextField(
            controller: _accountController,
            hint: 'Account number',
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          const OnboardingFieldLabel('Confirm account number'),
          OnboardingTextField(
            controller: _confirmController,
            hint: 'Re-enter account number',
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          Text(
            'Your bank details are encrypted in transit and used only for payouts.',
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
