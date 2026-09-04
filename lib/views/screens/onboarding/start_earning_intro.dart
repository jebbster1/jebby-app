import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/views/screens/onboarding/what_youll_need.dart';

class StartEarningIntroScreen extends StatelessWidget {
  const StartEarningIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showStepProgress: false,
      showBackButton: false,
      title: 'Start Earning',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Earning with Jebby',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete a few quick steps to securely rent out your items and get paid.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _StepPreviewItem(
            number: 1,
            title: 'Verify Your Identity',
            subtitle: 'Basic info for community safety.',
          ),
          const SizedBox(height: 16),
          _StepPreviewItem(
            number: 2,
            title: 'Set Up Payouts',
            subtitle: 'Add a bank account to receive earnings.',
          ),
          const SizedBox(height: 16),
          _StepPreviewItem(
            number: 3,
            title: 'List Your First Item',
            subtitle: 'Add item details and start earning.',
          ),
          const SizedBox(height: 32),
          Text(
            'It only takes a few minutes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: 'Continue',
          onPressed: () => Get.to(() => const WhatYoullNeedScreen()),
        ),
      ),
    );
  }
}

class _StepPreviewItem extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;

  const _StepPreviewItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
