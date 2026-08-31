import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../res/app_url.dart';
import '../../../res/color.dart';

class ReservationFlowTheme {
  final String phase;

  const ReservationFlowTheme(this.phase);

  bool get isReturn => phase == 'return';

  Color get accent => isReturn ? AppColors.primaryColor : const Color(0xFF2563EB);

  Color get accentSoft => isReturn ? const Color(0xFFFFF4E5) : const Color(0xFFEFF6FF);

  Color get accentBorder => isReturn ? const Color(0xFFFFE0B2) : const Color(0xFFBFDBFE);

  String get beginInspectionLabel =>
      isReturn ? 'Begin Return Inspection' : 'Begin Pickup Inspection';

  String get continueInspectionLabel =>
      isReturn ? 'Continue Return Inspection' : 'Continue Pickup Inspection';

  String get reviewConfirmLabel => 'Review & Confirm';

  String get arrivalTitle => isReturn ? 'Return Details' : 'Pickup Details';

  String get arrivalPrompt =>
      isReturn ? 'Please go to the return location.' : 'Please go to the pickup location.';

  String get arrivalButtonLabel =>
      isReturn ? "I'm at the Return Location" : "I'm at the Pickup Location";

  String get inspectTitle => isReturn ? 'Inspect Returned Item' : 'Inspect Item';

  String get confirmTitle => isReturn ? 'Return Condition Confirmation' : 'Condition Confirmation';

  String get confirmButtonLabel =>
      isReturn ? 'Confirm Return' : 'Confirm Acceptable Condition';

  String get successTitle => isReturn ? 'Rental Complete!' : 'Rental Started!';

  String get successSubtitle => isReturn
      ? 'The rental has been completed successfully.'
      : 'The rental is now active.';

  String get handoffInfoTitle => isReturn ? 'Return Info' : 'Pickup Info';

  ButtonStyle primaryButton({double height = 52}) {
    return FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      disabledBackgroundColor: accent.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: Size.fromHeight(height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }

  ButtonStyle secondaryButton({double height = 48}) {
    return OutlinedButton.styleFrom(
      foregroundColor: accent,
      disabledForegroundColor: accent.withValues(alpha: 0.55),
      side: BorderSide(color: accent),
      disabledBackgroundColor: Colors.transparent,
      minimumSize: Size.fromHeight(height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }
}

String reservationImageUrl(String? path) {
  final p = path?.trim() ?? '';
  if (p.isEmpty) return '';
  if (p.toLowerCase().startsWith('http')) return p;
  final base = AppUrl.baseUrlM.endsWith('/') ? AppUrl.baseUrlM : '${AppUrl.baseUrlM}/';
  final rel = p.startsWith('/') ? p.substring(1) : p;
  return '$base$rel';
}
