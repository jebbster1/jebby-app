import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/vendors/my_products.dart';
import 'package:jebby/views/screens/vendors/add_product.dart';

class ListingSuccessScreen extends StatelessWidget {
  const ListingSuccessScreen({super.key});

  static const Color _primaryGold = Color(0xFFF6AE02);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _SuccessCheckWithConfetti(),
              const SizedBox(height: 28),
              const _ListingLiveIllustration(),
              const SizedBox(height: 32),
              Text(
                'Your listing is live!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Great job! Your item is now visible to thousands of renters.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6B6B),
                  height: 1.45,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Get.offAll(() => MyProductsScreen(side: false));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryGold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'View My Listing',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Get.offAll(
                      () => const AddProductScreen(popToProductsOnBack: true),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'List Another Item',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCheckWithConfetti extends StatelessWidget {
  const _SuccessCheckWithConfetti();

  static const Color _gold = Color(0xFFF6AE02);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const _ConfettiPiece(
            left: 8,
            top: 18,
            width: 10,
            height: 4,
            color: Color(0xFF4285F4),
            angle: -0.6,
          ),
          const _ConfettiPiece(
            right: 6,
            top: 8,
            width: 8,
            height: 8,
            color: Color(0xFFF6AE02),
            shape: BoxShape.circle,
          ),
          const _ConfettiPiece(
            left: 22,
            top: 4,
            width: 6,
            height: 6,
            color: Color(0xFFFF8A50),
            shape: BoxShape.circle,
          ),
          const _ConfettiPiece(
            right: 18,
            top: 28,
            width: 12,
            height: 4,
            color: Color(0xFF4285F4),
            angle: 0.8,
          ),
          const _ConfettiPiece(
            left: 4,
            bottom: 24,
            width: 8,
            height: 4,
            color: Color(0xFFFF8A50),
            angle: -1.1,
          ),
          const _ConfettiPiece(
            right: 10,
            bottom: 18,
            width: 6,
            height: 6,
            color: Color(0xFFF6AE02),
            shape: BoxShape.circle,
          ),
          const _ConfettiPiece(
            left: 36,
            bottom: 8,
            width: 10,
            height: 4,
            color: Color(0xFF4285F4),
            angle: 0.4,
          ),
          const _ConfettiPiece(
            right: 28,
            bottom: 6,
            width: 8,
            height: 4,
            color: Color(0xFFFF8A50),
            angle: -0.3,
          ),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _gold,
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
}

class _ConfettiPiece extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
  final Color color;
  final double angle;
  final BoxShape shape;

  const _ConfettiPiece({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    required this.color,
    this.angle = 0,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle
                    ? BorderRadius.circular(2)
                    : null,
          ),
        ),
      ),
    );
  }
}

class _ListingLiveIllustration extends StatelessWidget {
  const _ListingLiveIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            left: 28,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6BBF59),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Container(
                  width: 22,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF6AE02).withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            child: CustomPaint(
              size: const Size(120, 96),
              painter: _ArmchairPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArmchairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFF6AE02);
    const goldDark = Color(0xFFE09000);

    final shadowPaint =
        Paint()
          ..color = goldDark.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bodyPaint = Paint()..color = gold;
    final cushionPaint = Paint()..color = const Color(0xFFFFC94A);

    final body =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, 28, size.width - 16, size.height - 36),
          const Radius.circular(18),
        );
    canvas.drawRRect(body, shadowPaint);
    canvas.drawRRect(body, bodyPaint);

    final back =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 8, size.width - 28, 48),
          const Radius.circular(20),
        );
    canvas.drawRRect(back, bodyPaint);

    final leftArm =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 34, 22, 44),
          const Radius.circular(14),
        );
    canvas.drawRRect(leftArm, bodyPaint);

    final rightArm =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - 22, 34, 22, 44),
          const Radius.circular(14),
        );
    canvas.drawRRect(rightArm, bodyPaint);

    final seat =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24, 52, size.width - 48, 28),
          const Radius.circular(12),
        );
    canvas.drawRRect(seat, cushionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
