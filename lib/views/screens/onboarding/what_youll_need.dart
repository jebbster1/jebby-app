import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/onboarding/before_you_continue.dart';
import 'package:jebby/views/screens/onboarding/onboarding_scaffold.dart';

class WhatYoullNeedScreen extends StatelessWidget {
  const WhatYoullNeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showStepProgress: false,
      title: 'Get Ready',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's get you ready to earn",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          const _ChecklistItem(
            icon: Icons.badge_outlined,
            title: 'Government-issued ID',
            subtitle: "Driver's license, passport, or state ID.",
          ),
          const SizedBox(height: 16),
          const _ChecklistItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Basic details to verify your identity.',
          ),
          const SizedBox(height: 16),
          const _ChecklistItem(
            icon: Icons.account_balance_outlined,
            title: 'Bank Account',
            subtitle: 'To receive payouts securely through Stripe.',
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.darkBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your information is secure and protected.',
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
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: 'Continue',
          onPressed: () => Get.to(() => const BeforeYouContinueScreen()),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, color: AppColors.darkBlue, size: 22),
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
