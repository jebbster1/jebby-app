import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/Views/screens/onboarding/stripe_welcome.dart';

class BeforeYouContinueScreen extends StatelessWidget {
  const BeforeYouContinueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showStepProgress: false,
      title: 'Safety',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(Icons.shield_outlined, color: darkBlue, size: 36),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'A safe community starts with you',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          const _TrustBullet(
            text: 'Your information is encrypted and securely stored.',
          ),
          const SizedBox(height: 12),
          const _TrustBullet(
            text: 'We never rent out or sell your personal data.',
          ),
          const SizedBox(height: 12),
          const _TrustBullet(
            text: "You're in control of your account and listings.",
          ),
          const SizedBox(height: 12),
          const _TrustBullet(
            text:
                'Data is only used for identity verification and payouts.',
          ),
          const SizedBox(height: 24),
          const OnboardingStripeFooter(),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: 'Continue',
          onPressed: () => Get.to(() => const StripeWelcomeScreen()),
        ),
      ),
    );
  }
}

class _TrustBullet extends StatelessWidget {
  final String text;

  const _TrustBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: darkBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
