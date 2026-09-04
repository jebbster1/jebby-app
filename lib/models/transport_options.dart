import 'handoff_window.dart';

class TransportOptions {
  final bool pickup;
  final bool delivery;
  final int? deliveryRadiusMiles;
  final String? deliveryCharges;
  final List<HandoffWindow> handoffWindows;

  TransportOptions({
    required this.pickup,
    required this.delivery,
    this.deliveryRadiusMiles,
    this.deliveryCharges,
    this.handoffWindows = const [],
  });

  factory TransportOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TransportOptions(pickup: true, delivery: false);
    }
    final windows = <HandoffWindow>[];
    final rawWindows = json['handoff_windows'];
    if (rawWindows is List) {
      for (final item in rawWindows) {
        if (item is Map<String, dynamic>) {
          windows.add(HandoffWindow.fromJson(item));
        } else if (item is Map) {
          windows.add(HandoffWindow.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return TransportOptions(
      pickup: json['pickup'] == true || json['pickup'] == 1,
      delivery: json['delivery'] == true || json['delivery'] == 1,
      deliveryRadiusMiles: json['delivery_radius_miles'] is int
          ? json['delivery_radius_miles']
          : int.tryParse('${json['delivery_radius_miles']}'),
      deliveryCharges: json['delivery_charges']?.toString(),
      handoffWindows: windows,
    );
  }

  Map<String, dynamic> toJson() => {
    'offers_pickup': pickup ? 1 : 0,
    'offers_delivery': delivery ? 1 : 0,
    'delivery_radius_miles': deliveryRadiusMiles,
    'delivery_charges': deliveryCharges ?? '0',
    'handoff_windows': handoffWindows.map((w) => w.toJson()).toList(),
  };
}
