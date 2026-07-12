import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/onboarding/all_set.dart';
import 'package:jebby/Views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/Views/screens/onboarding/personal_details_screen.dart';
import 'package:jebby/model/onboarding_state.dart';
import 'package:jebby/view_model/onboarding_controller.dart';

class StripeWelcomeScreen extends StatefulWidget {
  final bool isFromTransactions;

  const StripeWelcomeScreen({
    super.key,
    this.isFromTransactions = false,
  });

  @override
  State<StripeWelcomeScreen> createState() => _StripeWelcomeScreenState();
}

class _StripeWelcomeScreenState extends State<StripeWelcomeScreen> {
  late final OnboardingController _controller = ensureOnboardingController();

  @override
  void initState() {
    super.initState();

    if (_controller.state.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => const AllSetScreen());
      });
    }
  }

  Future<void> _continue() async {
    await _controller.markIntroSeen();
    await _controller.advanceTo(OnboardingSteps.formStart);
    if (!mounted) return;
    Get.to(() => const PersonalDetailsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showStepProgress: false,
      title: 'Verification',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF635BFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Color(0xFF635BFF),
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Jebby partners with Stripe for secure payouts',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete a few quick steps in the app to verify your identity and connect your bank account for payouts.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trusted by global companies',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amazon, Airbnb, Uber, and millions of businesses partner with Stripe for payments and payouts.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _StripePartnerChip(
                  logoAsset: 'assets/onboarding/stripe_partners/amazon.svg',
                  logoColor: Color(0xFF232F3E),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StripePartnerChip(
                  logoAsset: 'assets/onboarding/stripe_partners/airbnb.svg',
                  logoColor: Color(0xFFFF5A5F),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StripePartnerChip(
                  logoAsset: 'assets/onboarding/stripe_partners/uber.svg',
                  logoColor: Color(0xFF09091A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _BenefitItem(
            icon: Icons.verified_user_outlined,
            text: 'Bank-level security for your personal and financial data',
          ),
          const SizedBox(height: 12),
          const _BenefitItem(
            icon: Icons.payments_outlined,
            text: 'Fast, reliable payouts directly to your bank account',
          ),
          const SizedBox(height: 12),
          const _BenefitItem(
            icon: Icons.fact_check_outlined,
            text: 'Upload your government ID for identity verification',
          ),
          const SizedBox(height: 24),
          const OnboardingStripeFooter(),
          const SizedBox(height: 16),
          Text(
            'By continuing, you agree to Stripe\'s Terms of Service and Privacy Policy.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.black38,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: OnboardingPrimaryButton(
          label: 'Continue',
          onPressed: _continue,
        ),
      ),
    );
  }
}

class _StripePartnerChip extends StatelessWidget {
  final String logoAsset;
  final Color logoColor;

  const _StripePartnerChip({
    required this.logoAsset,
    required this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            child: SvgPicture.asset(
              logoAsset,
              height: 28,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uses Stripe',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: darkBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
