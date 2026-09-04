import 'dart:convert';

/// Product context embedded in chat when a renter messages from product detail.
class ProductChatContext {
  static const String payloadPrefix = 'JEBBY_PRODUCT|';

  final String productId;
  final String name;
  final String price;
  final String image;
  final String vendorUserId;
  final String recipientId;

  const ProductChatContext({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.vendorUserId,
    required this.recipientId,
  });

  String toPayload() {
    return '$payloadPrefix${jsonEncode({
      'product_id': productId,
      'name': name,
      'price': price,
      'image': image,
      'vendor_user_id': vendorUserId,
      'recipient_id': recipientId,
    })}';
  }

  String get imageUrl {
    final t = image.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http')) return t;
    return t;
  }

  static ProductChatContext? tryParsePayload(String? content) {
    if (content == null) return null;
    final trimmed = content.trim();
    if (!trimmed.startsWith(payloadPrefix)) return null;
    try {
      final map = jsonDecode(trimmed.substring(payloadPrefix.length));
      if (map is! Map) return null;
      final id = (map['product_id'] ?? '').toString();
      if (id.isEmpty) return null;
      final vendorId = (map['vendor_user_id'] ?? '').toString();
      return ProductChatContext(
        productId: id,
        name: (map['name'] ?? '').toString(),
        price: (map['price'] ?? '').toString(),
        image: (map['image'] ?? '').toString(),
        vendorUserId: vendorId,
        recipientId: (map['recipient_id'] ?? vendorId).toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static String? recipientIdFromPayload(String? content) {
    return tryParsePayload(content)?.recipientId;
  }

  /// Provider tab: current user is the listing vendor (`vendor_user_id` == [currentUserId]).
  static bool isProviderTabThread({
    String? inquiryContent,
    required String currentUserId,
  }) {
    final ctx = tryParsePayload(inquiryContent);
    if (ctx == null) return false;
    if (currentUserId.trim().isEmpty) return false;
    return ctx.vendorUserId.trim() == currentUserId.trim();
  }

  /// Renter tab: product inquiry where someone else owns the listing.
  static bool isRenterTabThread({
    String? inquiryContent,
    required String currentUserId,
  }) {
    final ctx = tryParsePayload(inquiryContent);
    if (ctx == null) return false;
    return !isProviderTabThread(
      inquiryContent: inquiryContent,
      currentUserId: currentUserId,
    );
  }

  /// Builds a minimal payload for threads that only have `product_id` on the row.
  static String syntheticPayload({
    required int productId,
    required String vendorUserId,
    required String recipientId,
  }) {
    return '$payloadPrefix${jsonEncode({
      'product_id': productId.toString(),
      'vendor_user_id': vendorUserId,
      'recipient_id': recipientId,
    })}';
  }

  static bool threadContainsProduct(
    Iterable<String?> contents,
    String productId,
  ) {
    for (final c in contents) {
      final ctx = tryParsePayload(c);
      if (ctx != null && ctx.productId == productId) return true;
    }
    return false;
  }

  static const String lastMessagePreviewLabel = 'Product Inquiry';

  static String formatLastMessagePreview(String? content) {
    if (content == null || content.trim().isEmpty) return '';
    final trimmed = content.trim();
    if (trimmed.startsWith(payloadPrefix) || tryParsePayload(trimmed) != null) {
      return lastMessagePreviewLabel;
    }
    return trimmed;
  }

  static bool threadHasProduct({
    required Iterable<String?> contents,
    required Iterable<int?> productIds,
    required String productId,
  }) {
    if (threadContainsProduct(contents, productId)) return true;
    for (final id in productIds) {
      if (id != null && id.toString() == productId) return true;
    }
    return false;
  }
}
