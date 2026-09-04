import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class InsuranceAndIndemnificationsScreen extends StatelessWidget {
  const InsuranceAndIndemnificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.insurance,
      title: 'Insurance & Indemnifications Policy',
    );
  }
}
