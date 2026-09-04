import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.terms,
      title: 'Terms and Conditions',
      emptyMessage: 'Unable to load terms. Please try again later.',
    );
  }
}
