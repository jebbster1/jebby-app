import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';

class LoaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
  }
}
