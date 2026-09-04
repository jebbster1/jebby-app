import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';

class ProfileImage {
  static const assetPath = 'assets/images/blankuser.png';

  static bool isValidPath(String? path) {
    final trimmed = path?.trim() ?? '';
    return trimmed.isNotEmpty && trimmed.toLowerCase() != 'null';
  }

  static String sanitizePath(String? path) {
    return isValidPath(path) ? path!.trim() : '';
  }

  static String? resolveUrl(String baseUrl, String? path) {
    if (!isValidPath(path)) return null;
    final trimmed = path!.trim();
    if (trimmed.toLowerCase().startsWith('http')) return trimmed;
    return baseUrl + trimmed;
  }

  static ImageProvider avatarProvider(String baseUrl, String? path) {
    final url = resolveUrl(baseUrl, path);
    if (url == null) return const AssetImage(assetPath);
    return NetworkImage(url);
  }

  static Widget circularAvatar({
    required double radius,
    required String baseUrl,
    String? imagePath,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
      );
    }

    final url = resolveUrl(baseUrl, imagePath);
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: url == null
            ? Image.asset(assetPath, fit: BoxFit.cover)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Image.asset(assetPath, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
