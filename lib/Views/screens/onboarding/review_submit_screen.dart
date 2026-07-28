import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/onboarding/all_set.dart';
import 'package:jebby/Views/screens/onboarding/bank_account_screen.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/Views/screens/onboarding/personal_details_screen.dart';
import 'package:jebby/Views/screens/onboarding/verify_identity_screen.dart';
import 'package:jebby/model/provider_onboarding_data.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:jebby/view_model/onboarding_controller.dart';
import 'package:jebby/Services/analytics_service.dart';

class ReviewSubmitScreen extends StatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  late final OnboardingController _controller = ensureOnboardingController();
  bool _tosAccepted = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.advanceTo(9);
    _tosAccepted = _controller.providerData.tosAccepted;
  }

  ProviderOnboardingData get _data => _controller.providerData;

  String get _dobText {
    final dob = _data.dateOfBirth;
    if (dob == null) return '—';
    return DateFormat.yMMMMd().format(dob);
  }

  String get _idTypeLabel =>
      ProviderIdType.labels[_data.idType] ?? _data.idType;

  String get _maskedAccount {
    final account = _data.accountNumber;
    if (account.isEmpty) return 'Re-enter on bank step';
    if (account.length <= 4) return '****';
    return '****${account.substring(account.length - 4)}';
  }

  String get _addressSummary {
    if (_data.addressLine1.isEmpty) return '—';
    final state = _data.addressState.isNotEmpty
        ? _data.addressState.toUpperCase()
        : '';
    return '${_data.addressLine1}, ${_data.addressCity}, $state ${_data.addressPostalCode}'
        .trim();
  }

  String get _identityDocumentsLabel {
    final frontPath = _data.frontImagePath;
    final hasFront = frontPath != null && File(frontPath).existsSync();
    if (!hasFront) return 'Missing — edit identity';
    if (_needsBack) {
      final backPath = _data.backImagePath;
      final hasBack = backPath != null && File(backPath).existsSync();
      if (!hasBack) return 'Back photo missing — edit identity';
    }
    return 'Ready to submit';
  }

  bool get _needsBack => ProviderIdType.requiresBack(_data.idType);

  String _formatSubmitError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('non-custom') ||
        lower.contains('express account') ||
        lower.contains('express')) {
      return 'A previous Stripe Express account exists for this user. '
          'Your backend must remove or migrate that account before Custom onboarding '
          'can succeed. Connect accounts are only created when submit fully succeeds.';
    }
    return message;
  }

  Future<void> _editPersonal() async {
    await Get.to(() => const PersonalDetailsScreen(returnToReview: true));
    if (mounted) setState(() {});
  }

  Future<void> _editIdentity() async {
    await Get.to(() => const VerifyIdentityScreen(returnToReview: true));
    if (mounted) setState(() {});
  }

  Future<void> _editBank() async {
    await Get.to(() => const BankAccountScreen(returnToReview: true));
    if (mounted) setState(() {});
  }

  void _toggleTosAccepted() {
    if (_isSubmitting) return;
    setState(() {
      _tosAccepted = !_tosAccepted;
      if (_tosAccepted) _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_tosAccepted) {
      setState(() => _errorMessage = 'Please accept the Connected Account Agreement.');
      return;
    }
    if (_controller.userId.isEmpty) {
      setState(() => _errorMessage = 'User session not found. Please sign in again.');
      return;
    }
    if (_data.frontImagePath == null ||
        !File(_data.frontImagePath!).existsSync()) {
      setState(() => _errorMessage = 'ID photos are required. Please edit identity.');
      return;
    }
    if (_needsBack &&
        (_data.backImagePath == null ||
            !File(_data.backImagePath!).existsSync())) {
      setState(
        () => _errorMessage = 'Back of ID is required. Please edit identity.',
      );
      return;
    }
    if (_data.accountNumber.isEmpty) {
      setState(
        () => _errorMessage = 'Bank account number is required. Please edit bank account.',
      );
      return;
    }
    final ssnLast4 = _controller.providerData.ssnLast4?.trim();
    if (ssnLast4 == null || ssnLast4.length != 4) {
      setState(
        () => _errorMessage = 'SSN last 4 is required. Please edit personal details.',
      );
      return;
    }
    if (_data.addressLine1.isEmpty ||
        _data.addressCity.isEmpty ||
        !_data.addressState.isNotEmpty ||
        !_data.addressPostalCode.isNotEmpty) {
      setState(
        () => _errorMessage = 'Home address is required. Please edit personal details.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    AnalyticsService.instance.track('stripe_onboarding_submitted');

    await _controller.updateProviderData(
      _controller.providerData.copyWith(
        tosAccepted: true,
        ssnLast4: ssnLast4,
      ),
    );

    try {
      final uploadResponse =
          await ApiRepository.shared.uploadIdentityDocumentFuture(
        userId: _controller.userId,
        documentType: _data.idType,
        frontPath: _data.frontImagePath!,
        backPath: _needsBack ? _data.backImagePath : null,
      );

      final frontFileId = uploadResponse['front_file_id']?.toString();
      if (frontFileId == null || frontFileId.isEmpty) {
        throw Exception('Could not upload identity document.');
      }

      await _controller.updateProviderData(
        _controller.providerData.copyWith(
          frontFileId: frontFileId,
          backFileId: uploadResponse['back_file_id']?.toString(),
          ssnLast4: ssnLast4,
        ),
      );

      final response =
          await ApiRepository.shared.submitProviderOnboardingFuture(
        body: _controller.providerData.copyWith(ssnLast4: ssnLast4).toSubmitJson(
          userId: _controller.userId,
        ),
      );

      if (!mounted) return;

      final status = response['status']?.toString() ?? '';
      final accountId = response['account_id']?.toString();
      final responseMessage = _formatSubmitError(
        ApiRepository.extractApiErrorMessage(
          response,
          fallback: 'Unable to complete onboarding.',
        ),
      );

      if (status == 'requires_info' ||
          status == 'error' ||
          status == 'failed' ||
          status == 'failure') {
        setState(() {
          _isSubmitting = false;
          _errorMessage = responseMessage;
        });
        return;
      }

      if (status == 'active' || status == 'pending') {
        await _controller.clearSensitiveProviderData();
        await _controller.markComplete(accountId: accountId);
        await _controller.completeProviderRole();
        if (!mounted) return;
        Get.off(() => const AllSetScreen());
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = responseMessage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _formatSubmitError(
          ApiRepository.extractApiErrorMessage(
            error,
            fallback: error.toString(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 9,
      title: 'Review & Submit',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your information',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Identity documents and your Stripe account are only sent when you tap Submit.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _SummarySection(
            title: 'Personal details',
            onEdit: _editPersonal,
            rows: [
              _SummaryRow('Name', _data.legalFullName),
              _SummaryRow('Email', _data.email),
              _SummaryRow('Phone', _data.phone),
              _SummaryRow('Date of birth', _dobText),
              _SummaryRow('SSN', _data.ssnLast4 != null ? '***-**-${_data.ssnLast4}' : '—'),
              _SummaryRow('Address', _addressSummary),
            ],
          ),
          _SummarySection(
            title: 'Identity',
            onEdit: _editIdentity,
            rows: [
              _SummaryRow('ID type', _idTypeLabel),
              _SummaryRow(
                'Documents',
                _identityDocumentsLabel,
              ),
            ],
          ),
          _SummarySection(
            title: 'Bank account',
            onEdit: _editBank,
            rows: [
              _SummaryRow('Account holder', _data.accountHolderName),
              _SummaryRow('Routing number', _data.routingNumber),
              _SummaryRow('Account number', _maskedAccount),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _tosAccepted,
                activeColor: darkBlue,
                onChanged: _isSubmitting
                    ? null
                    : (_) => _toggleTosAccepted(),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleTosAccepted,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'I agree to the Stripe Connected Account Agreement and authorize Jebby to share this information with Stripe for identity verification and payouts.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade800),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const OnboardingStripeFooter(),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: 'Submit',
          isLoading: _isSubmitting,
          onPressed: (_isSubmitting || !_tosAccepted) ? null : _submit,
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final List<_SummaryRow> rows;

  const _SummarySection({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkBlue,
                  ),
                ),
              ),
            ],
          ),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);
}
