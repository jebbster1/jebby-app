import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class MaintenanceAndWarrantiesScreen extends StatelessWidget {
  const MaintenanceAndWarrantiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.maintenance,
      title: 'Maintenance & Warranties',
      emptyMessage:
          'Unable to load maintenance & warranties policy. Please try again later.',
    );
  }
}
