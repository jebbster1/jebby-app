import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class UsagePolicyAndLimitationsScreen extends StatelessWidget {
  const UsagePolicyAndLimitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.usagePolicy,
      title: 'Usage Policy & Limitations',
    );
  }
}
