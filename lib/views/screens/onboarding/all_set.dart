import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/onboarding/onboarding_scaffold.dart';
import 'package:jebby/views/screens/vendors/add_product.dart';
import 'package:jebby/views/screens/vendors/vendor_home.dart';
import 'package:jebby/view_models/onboarding_controller.dart';

class AllSetScreen extends StatefulWidget {
  const AllSetScreen({super.key});

  @override
  State<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends State<AllSetScreen> {
  late final OnboardingController _controller = ensureOnboardingController();
  bool _isCompleting = true;

  @override
  void initState() {
    super.initState();
    _finalizeOnboarding();
  }

  Future<void> _finalizeOnboarding() async {
    await _controller.advanceTo(10);
    await _controller.completeProviderRole();
    if (mounted) setState(() => _isCompleting = false);
  }

  void _listFirstItem() {
    Get.offAll(() => const AddProductScreen(popToHomeOnBack: true));
  }

  void _maybeLater() {
    Get.offAll(() => VendorHomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 10,
      title: 'All Set',
      showBackButton: false,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const _SuccessHeroIcon(),
                const SizedBox(height: 24),
                Text(
                  "You're all set!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is verified and ready to start earning.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SuccessCheckItem(label: 'Identity verified'),
                        SizedBox(height: 14),
                        _SuccessCheckItem(label: 'Payouts set up'),
                        SizedBox(height: 14),
                        _SuccessCheckItem(label: 'Account activated'),
                      ],
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
        child: Column(
          children: [
            OnboardingPrimaryButton(
              label: 'List Your First Item',
              isLoading: _isCompleting,
              onPressed: _isCompleting ? null : _listFirstItem,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isCompleting ? null : _maybeLater,
              child: Text(
                'Maybe Later',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHeroIcon extends StatelessWidget {
  const _SuccessHeroIcon();

  static const Color _successYellow = Color(0xFFF6AE02);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ..._confettiPieces(),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _successYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _confettiPieces() {
    const pieces = [
      _ConfettiPiece(left: 8, top: 18, size: 7, color: Color(0xFF4285F4), isDot: true),
      _ConfettiPiece(left: 22, top: 4, size: 8, color: Color(0xFF22C55E), isDot: true),
      _ConfettiPiece(left: 92, top: 10, size: 6, color: Color(0xFFF6AE02), isDot: true),
      _ConfettiPiece(left: 104, top: 28, size: 7, color: Color(0xFFEC4899), isDot: true),
      _ConfettiPiece(left: 14, top: 78, size: 6, color: Color(0xFF22C55E), isDot: true),
      _ConfettiPiece(left: 98, top: 82, size: 7, color: Color(0xFF4285F4), isDot: true),
      _ConfettiPiece(left: 6, top: 46, width: 10, height: 3, color: Color(0xFFF6AE02), rotation: 0.5),
      _ConfettiPiece(left: 100, top: 52, width: 9, height: 3, color: Color(0xFFEC4899), rotation: -0.4),
      _ConfettiPiece(left: 48, top: 2, width: 8, height: 3, color: Color(0xFF4285F4), rotation: 0.2),
      _ConfettiPiece(left: 54, top: 96, width: 10, height: 3, color: Color(0xFF22C55E), rotation: -0.3),
    ];
    return pieces;
  }
}

class _ConfettiPiece extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  final double width;
  final double height;
  final Color color;
  final bool isDot;
  final double rotation;

  const _ConfettiPiece({
    required this.left,
    required this.top,
    required this.color,
    this.size = 6,
    this.width = 8,
    this.height = 3,
    this.isDot = false,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: isDot ? size : width,
          height: isDot ? size : height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDot ? size : 2),
          ),
        ),
      ),
    );
  }
}

class _SuccessCheckItem extends StatelessWidget {
  final String label;

  const _SuccessCheckItem({required this.label});

  static const Color _successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: _successGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
