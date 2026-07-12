import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/onboarding/bank_account_screen.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_form_widgets.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/model/provider_onboarding_data.dart';
import 'package:jebby/view_model/onboarding_controller.dart';

class VerifyIdentityScreen extends StatefulWidget {
  final bool returnToReview;

  const VerifyIdentityScreen({
    super.key,
    this.returnToReview = false,
  });

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  late final OnboardingController _controller = ensureOnboardingController();
  final ImagePicker _picker = ImagePicker();
  late String _idType;
  String? _frontPath;
  String? _backPath;

  @override
  void initState() {
    super.initState();
    if (!widget.returnToReview) {
      _controller.advanceTo(7);
    }
    final data = _controller.providerData;
    _idType = data.idType;
    _frontPath = data.frontImagePath;
    _backPath = data.backImagePath;
  }

  bool get _needsBack => ProviderIdType.requiresBack(_idType);

  void _showError(String message) {
    Get.snackbar(
      'Verification',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _pickImage(bool isBack) async {
    final source = await showOnboardingImageSourceSheet(context);
    if (source == null) return;

    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    setState(() {
      if (isBack) {
        _backPath = file.path;
      } else {
        _frontPath = file.path;
      }
    });
  }

  Future<void> _continue() async {
    if (_frontPath == null || !File(_frontPath!).existsSync()) {
      _showError('Please upload the front of your ID.');
      return;
    }
    if (_needsBack && (_backPath == null || !File(_backPath!).existsSync())) {
      _showError('Please upload the back of your ID.');
      return;
    }

    await _controller.updateProviderData(
      _controller.providerData.copyWith(
        idType: _idType,
        frontImagePath: _frontPath,
        backImagePath: _backPath,
        clearFrontFileId: true,
        clearBackFileId: true,
      ),
    );

    if (widget.returnToReview) {
      await _controller.advanceTo(9);
      Get.back();
      return;
    }

    await _controller.advanceTo(8);
    Get.to(() => const BankAccountScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 7,
      title: 'Verify Identity',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingSectionTitle(
            'Upload your government ID',
            subtitle:
                'Choose your ID type and upload clear photos. Documents are sent to Stripe when you submit on the final step.',
          ),
          Text(
            'ID type',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...ProviderIdType.labels.entries.map((entry) {
            return RadioListTile<String>(
              value: entry.key,
              groupValue: _idType,
              contentPadding: EdgeInsets.zero,
              activeColor: darkBlue,
              title: Text(
                entry.value,
                style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _idType = value;
                  if (!ProviderIdType.requiresBack(value)) {
                    _backPath = null;
                  }
                });
              },
            );
          }),
          const SizedBox(height: 8),
          _UploadTile(
            label: 'Front of ID',
            path: _frontPath,
            onTap: () => _pickImage(false),
          ),
          if (_needsBack) ...[
            const SizedBox(height: 12),
            _UploadTile(
              label: 'Back of ID',
              path: _backPath,
              onTap: () => _pickImage(true),
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
          label: widget.returnToReview ? 'Save' : 'Continue',
          onPressed: _continue,
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onTap;

  const _UploadTile({
    required this.label,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && File(path!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.file(File(path!), fit: BoxFit.cover)
                  : Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasImage ? 'Tap to replace' : 'Tap to upload',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
