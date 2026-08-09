import 'package:flutter/material.dart';

import '../../../constants/cms_slugs.dart';
import 'cms_policy_screen.dart';

class RentalAgreement extends StatelessWidget {
  const RentalAgreement({super.key});

  @override
  Widget build(BuildContext context) {
    return const CmsPolicyScreen(
      slug: CmsSlugs.rentalAgreement,
      title: 'Rental Agreement',
    );
  }
}
