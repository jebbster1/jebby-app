import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showAppSnackbar(String title, String message, {Color? backgroundColor}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
    backgroundColor: backgroundColor ?? const Color(0x99323232),
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );
}

void showAppErrorSnackbar(String message, {String title = 'Error'}) {
  showAppSnackbar(
    title,
    message,
    backgroundColor: const Color(0x99E53935),
  );
}

void showAppSuccessSnackbar(String message, {String title = 'Success'}) {
  showAppSnackbar(
    title,
    message,
    backgroundColor: const Color(0x9943A047),
  );
}
