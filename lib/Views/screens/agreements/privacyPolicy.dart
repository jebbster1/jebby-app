import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.privacy,
      title: 'Privacy Policy',
      emptyMessage: 'Unable to load privacy policy. Please try again later.',
    );
  }
}
