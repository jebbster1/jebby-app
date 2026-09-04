import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy.dart';

class RentalAgreementScreen extends StatelessWidget {
  const RentalAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.rentalAgreement,
      title: 'Rental Agreement',
    );
  }
}
