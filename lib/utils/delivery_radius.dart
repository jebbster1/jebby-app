import 'package:geolocator/geolocator.dart';

class DeliveryRadius {
  static const double _metersPerMile = 1609.344;

  static double distanceMiles(
    double listingLat,
    double listingLng,
    double deliveryLat,
    double deliveryLng,
  ) {
    final meters = Geolocator.distanceBetween(
      listingLat,
      listingLng,
      deliveryLat,
      deliveryLng,
    );
    return meters / _metersPerMile;
  }

  static bool isWithinRadius({
    required double listingLat,
    required double listingLng,
    required double deliveryLat,
    required double deliveryLng,
    required int? radiusMiles,
  }) {
    if (radiusMiles == null || radiusMiles <= 0) return true;
    final miles = distanceMiles(listingLat, listingLng, deliveryLat, deliveryLng);
    return miles <= radiusMiles;
  }

  static String outOfRangeMessage(int radiusMiles) {
    return 'Delivery address is outside the $radiusMiles mile delivery radius for this listing.';
  }

  static String snackbarTitleForMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('delivery radius') || lower.contains('outside')) {
      return 'Out of range';
    }
    return 'Error';
  }

  static String? validationError({
    required double? listingLat,
    required double? listingLng,
    required double? deliveryLat,
    required double? deliveryLng,
    required int? radiusMiles,
  }) {
    if (radiusMiles == null || radiusMiles <= 0) return null;
    if (listingLat == null ||
        listingLng == null ||
        deliveryLat == null ||
        deliveryLng == null) {
      return null;
    }
    if (isWithinRadius(
      listingLat: listingLat,
      listingLng: listingLng,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      radiusMiles: radiusMiles,
    )) {
      return null;
    }
    return outOfRangeMessage(radiusMiles);
  }
}
