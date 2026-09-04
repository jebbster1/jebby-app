import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class CopyrightPolicyScreen extends StatelessWidget {
  const CopyrightPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.copyright,
      title: 'Copyright Policy',
    );
  }
}
