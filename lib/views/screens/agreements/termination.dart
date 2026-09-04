import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class TerminationScreen extends StatelessWidget {
  const TerminationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.termination,
      title: 'Termination',
    );
  }
}
