import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class CopyrightPolicy extends StatelessWidget {
  const CopyrightPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.copyright,
      title: 'Copyright Policy',
    );
  }
}
