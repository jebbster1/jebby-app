import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/constants/color.dart';

/// Shared layout for CMS-style pages (About, Terms, Contact Support, API HTML policies).
/// Light grey background, no cards; app bar matches renter My Profile pattern.
class CmsPageShell extends StatelessWidget {
  const CmsPageShell({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  static const Color pageBackground = Color(0xFFF5F5F5);
  static const double horizontalPadding = 22;

  static TextStyle headingLarge() => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.25,
      );

  static TextStyle headingSection() => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        height: 1.3,
      );

  static TextStyle bodyParagraph() => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF374151),
        height: 1.55,
      );

  static Widget paddedScroll({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 32),
      child: child,
    );
  }

  static Widget sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
    );
  }

  /// Scroll area for API-loaded HTML (terms, privacy, rental policies, etc.).
  static Widget htmlPolicyScroll({
    required bool isLoading,
    required bool isError,
    required bool emptyData,
    required String? html,
    String emptyMessage = 'Unable to load content. Please try again later.',
  }) {
    return paddedScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
            )
          else if (isError || emptyData || html == null || html.isEmpty)
            Text(emptyMessage, style: bodyParagraph())
          else
            Html(
              data: html,
              style: htmlStyles(),
            ),
        ],
      ),
    );
  }

  /// Styling for [Html] from `flutter_html` to match plain CMS text pages.
  static Map<String, Style> htmlStyles() {
    final inter = GoogleFonts.inter().fontFamily;
    return {
      'body': Style(
        margin: Margins.zero,
        fontSize: FontSize(16),
        color: const Color(0xFF374151),
        fontFamily: inter,
        lineHeight: const LineHeight(1.55),
      ),
      'p': Style(
        margin: Margins.only(bottom: 12),
        fontSize: FontSize(16),
        lineHeight: const LineHeight(1.55),
      ),
      'h1': Style(
        fontSize: FontSize(22),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        margin: Margins.only(bottom: 12, top: 4),
        fontFamily: inter,
      ),
      'h2': Style(
        fontSize: FontSize(18),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        margin: Margins.only(bottom: 10, top: 20),
        fontFamily: inter,
      ),
      'h3': Style(
        fontSize: FontSize(17),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        margin: Margins.only(bottom: 8, top: 14),
        fontFamily: inter,
      ),
      'li': Style(
        fontSize: FontSize(16),
        lineHeight: const LineHeight(1.5),
        margin: Margins.only(bottom: 6),
      ),
      'ul': Style(
        margin: Margins.only(bottom: 12),
      ),
      'ol': Style(
        margin: Margins.only(bottom: 12),
      ),
      'a': Style(
        color: const Color(0xFF2563EB),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black87),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: body,
    );
  }
}
