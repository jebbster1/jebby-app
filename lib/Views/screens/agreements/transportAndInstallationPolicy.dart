import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class TransportAndInstallationPolicy extends StatelessWidget {
  const TransportAndInstallationPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.transport,
      title: 'Transportation & Installation Policy',
    );
  }
}
