import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class TransportAndInstallationPolicyScreen extends StatelessWidget {
  const TransportAndInstallationPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.transport,
      title: 'Transportation & Installation Policy',
    );
  }
}
