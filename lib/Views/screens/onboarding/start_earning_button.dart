import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/model/onboarding_state.dart';
import 'package:jebby/view_model/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartEarningButton extends StatefulWidget {
  const StartEarningButton({super.key});

  @override
  State<StartEarningButton> createState() => _StartEarningButtonState();
}

class _StartEarningButtonState extends State<StartEarningButton> {
  static const Color _bannerBlue = Color(0xFF2B65EC);
  static const Color _chevronBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapController());
  }

  Future<void> _bootstrapController() async {
    final controller = ensureOnboardingController();
    if (controller.userId.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id') ?? '';
    if (userId.isEmpty) return;

    await controller.loadAndReconcile(
      userId: userId,
      name: prefs.getString('fullname'),
      email: prefs.getString('email'),
      phone: prefs.getString('phoneNumber'),
    );
  }

  @override
  Widget build(BuildContext context) {
    ensureOnboardingController();

    return GetBuilder<OnboardingController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (controller.state.isComplete) {
          return const SizedBox.shrink();
        }

        final stepsRemaining = controller.state.stepsRemaining;
        final filledSegments = _drawerProgressFilled(
          status: controller.state.onboardingStatus,
          step: controller.state.onboardingStep,
        );
        final cardWidth = MediaQuery.of(context).size.width * 0.75;

        return SizedBox(
          width: cardWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.startOrResume(),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: _bannerBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: _chevronBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Earning',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rent out items and earn money nearby.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: _chevronBlue,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _StartEarningProgressCard(
                stepsRemaining: stepsRemaining,
                filledSegments: filledSegments,
              ),
            ],
          ),
        );
      },
    );
  }

  /// One segment per onboarding screen (Step 1–5 of 5).
  static int _drawerProgressFilled({
    required String status,
    required int step,
  }) {
    if (status == OnboardingStatus.notStarted) return 0;
    return OnboardingSteps.toDisplayStep(step);
  }
}

class _StartEarningProgressCard extends StatelessWidget {
  final int stepsRemaining;
  final int filledSegments;

  const _StartEarningProgressCard({
    required this.stepsRemaining,
    required this.filledSegments,
  });

  static const int _totalSegments = OnboardingSteps.formCount;
  static const Color _trackColor = Color(0xFFE2E5EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: darkBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF4A4D55),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: "You're "),
                        TextSpan(
                          text: '$stepsRemaining',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const TextSpan(
                          text: ' steps away from earning with Jebby.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_totalSegments, (index) {
              final isFilled = index < filledSegments;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < _totalSegments - 1 ? 6 : 0,
                  ),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: isFilled ? darkBlue : _trackColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
