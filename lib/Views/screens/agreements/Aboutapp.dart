import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.maintenance,
      title: 'Maintenance & Warranties',
    );
  }
}
