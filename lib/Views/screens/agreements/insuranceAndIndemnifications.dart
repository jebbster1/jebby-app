import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class InsuranceAndIndemnification extends StatelessWidget {
  const InsuranceAndIndemnification({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.insurance,
      title: 'Insurance & Indemnifications Policy',
    );
  }
}
