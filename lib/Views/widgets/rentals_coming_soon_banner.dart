import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/res/color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RentalsComingSoonBanner extends StatefulWidget {
  const RentalsComingSoonBanner({
    super.key,
    this.rentalsEnabledAt,
  });

  final DateTime? rentalsEnabledAt;

  static DateTime get defaultRentalsEnabledAt => DateTime(2026, 9, 25);

  static const String dismissedKey = 'rentals_coming_soon_banner_dismissed';

  @override
  State<RentalsComingSoonBanner> createState() =>
      _RentalsComingSoonBannerState();
}

class _RentalsComingSoonBannerState extends State<RentalsComingSoonBanner> {
  bool _dismissed = false;
  bool _prefsLoaded = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = prefs.getBool(RentalsComingSoonBanner.dismissedKey) ?? false;
      _prefsLoaded = true;
    });
  }

  void _tick() {
    final now = DateTime.now();
    final end = widget.rentalsEnabledAt ?? RentalsComingSoonBanner.defaultRentalsEnabledAt;
    final next = end.isAfter(now) ? end.difference(now) : Duration.zero;
    if (next != _remaining && mounted) {
      setState(() => _remaining = next);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RentalsComingSoonBanner.dismissedKey, true);
    if (!mounted) return;
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded || _dismissed || _remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀 Rentals Are Almost Here!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Feel free to browse categories and explore what\'s coming to Jebby.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CountdownUnit(value: days, label: 'Days'),
              const SizedBox(width: 8),
              _CountdownUnit(value: hours, label: 'Hrs'),
              const SizedBox(width: 8),
              _CountdownUnit(value: minutes, label: 'Min'),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: 'Renting will be enabled in $days day${days == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(
                  text: ' while we continue loading inventory.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _dismiss,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue Browsing',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
