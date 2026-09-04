import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSwitcherCard extends StatelessWidget {
  static const Color primaryGold = Color(0xFFE8A93A);
  static const Color cardBackground = Color(0xFFFFF7E6);
  static const Color borderColor = Color(0xFFE5E5E5);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B6B6B);

  final bool isEarnMode;
  final ValueChanged<bool> onModeChanged;
  final bool isLoading;

  const RoleSwitcherCard({
    super.key,
    required this.isEarnMode,
    required this.onModeChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT MODE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isEarnMode ? segmentWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryGold,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            label: 'Rent',
                            icon: Icons.search,
                            isActive: !isEarnMode,
                            onTap: isLoading || !isEarnMode
                                ? null
                                : () => onModeChanged(false),
                          ),
                        ),
                        Expanded(
                          child: _SegmentButton(
                            label: 'Earn',
                            icon: Icons.paid_outlined,
                            isActive: isEarnMode,
                            onTap: isLoading || isEarnMode
                                ? null
                                : () => onModeChanged(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.stars_rounded,
                size: 18,
                color: primaryGold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isEarnMode
                      ? 'Earn money by listing your items'
                      : 'Find and rent items nearby',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : RoleSwitcherCard.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
