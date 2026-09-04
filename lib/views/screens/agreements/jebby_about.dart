import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class JebbyAboutScreen extends StatelessWidget {
  const JebbyAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.aboutApp,
      title: 'About App',
    );
  }
}
