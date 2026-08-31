import 'order_dispute.dart';

class ReservationAction {
  final String type;
  final String label;

  ReservationAction({required this.type, required this.label});

  factory ReservationAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ReservationAction(type: 'none', label: 'No action required');
    }
    return ReservationAction(
      type: json['type']?.toString() ?? 'none',
      label: json['label']?.toString() ?? '',
    );
  }
}

/// Maps to the `orders` row plus reservation API enrichments.
class Reservation {
  static const _addressHiddenStatuses = {
    'BOOKING_REQUESTED',
    'ACCEPTED',
    'REJECTED',
    'CANCELLED',
  };

  static bool isAddressRevealed(String orderStatus) {
    return !_addressHiddenStatuses.contains(orderStatus);
  }

  final int id;
  final int userId;
  final int vendorId;
  final int productId;
  final String orderStatus;
  final String? handoffStatus;
  final int? handoffEtaMinutes;
  final String? handoffPhase;
  final String? transportType;
  final num transportFee;
  final String? pickupWindowBegin;
  final String? pickupWindowEnd;
  final String? returnWindowBegin;
  final String? returnWindowEnd;
  final String? rentalStartDate;
  final String? rentalEndDate;
  final num? totalPrice;
  final String? paymentIntentId;
  final String? completedAt;
  final String? disputeDeadlineAt;
  final String? payoutStatus;
  final String? payoutTransferId;
  final String? payoutReleasedAt;
  final num? vendorPayoutAmount;
  final num? securityDeposit;
  final String? depositRefundStatus;
  final String? depositRefundedAt;
  final String? location;
  final bool addressRevealed;
  final String? productName;
  final String? productImage;
  final String? role;
  final String? counterpartyLabel;
  final String? counterpartyName;
  final String? counterpartyImage;
  final ReservationAction nextAction;
  final OrderDispute? openDispute;
  final Map<String, dynamic>? policy;
  final num? paymentAmountDue;
  final num? paymentApplicationFees;
  final String? vendorStripeAccountId;
  final bool canUpdateHandoff;

  Reservation({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.productId,
    required this.orderStatus,
    this.handoffStatus,
    this.handoffEtaMinutes,
    this.handoffPhase,
    this.transportType,
    this.transportFee = 0,
    this.pickupWindowBegin,
    this.pickupWindowEnd,
    this.returnWindowBegin,
    this.returnWindowEnd,
    this.rentalStartDate,
    this.rentalEndDate,
    this.totalPrice,
    this.paymentIntentId,
    this.completedAt,
    this.disputeDeadlineAt,
    this.payoutStatus,
    this.payoutTransferId,
    this.payoutReleasedAt,
    this.vendorPayoutAmount,
    this.securityDeposit,
    this.depositRefundStatus,
    this.depositRefundedAt,
    this.location,
    this.addressRevealed = false,
    this.productName,
    this.productImage,
    this.role,
    this.counterpartyLabel,
    this.counterpartyName,
    this.counterpartyImage,
    required this.nextAction,
    this.openDispute,
    this.policy,
    this.paymentAmountDue,
    this.paymentApplicationFees,
    this.vendorStripeAccountId,
    this.canUpdateHandoff = false,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final status = json['order_status']?.toString() ?? 'BOOKING_REQUESTED';
    final openDisputeMap = json['open_dispute'];
    final paymentDue = json['payment_due'];
    final paymentDueMap = paymentDue is Map<String, dynamic>
        ? paymentDue
        : paymentDue is Map
        ? Map<String, dynamic>.from(paymentDue)
        : null;
    return Reservation(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      userId: json['user_id'] is int ? json['user_id'] : int.parse('${json['user_id']}'),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse('${json['vendor_id']}'),
      productId: json['product_id'] is int ? json['product_id'] : int.parse('${json['product_id']}'),
      orderStatus: status,
      handoffStatus: json['handoff_status']?.toString(),
      handoffEtaMinutes: json['handoff_eta_minutes'] is int
          ? json['handoff_eta_minutes']
          : int.tryParse('${json['handoff_eta_minutes']}'),
      handoffPhase: json['handoff_phase']?.toString(),
      transportType: json['transport_type']?.toString(),
      transportFee: num.tryParse('${json['transport_fee']}') ?? 0,
      pickupWindowBegin: json['pickup_window_begin']?.toString(),
      pickupWindowEnd: json['pickup_window_end']?.toString(),
      returnWindowBegin: json['return_window_begin']?.toString(),
      returnWindowEnd: json['return_window_end']?.toString(),
      rentalStartDate: json['rental_start_date']?.toString(),
      rentalEndDate: json['rental_end_date']?.toString(),
      totalPrice: num.tryParse('${json['total_price']}'),
      paymentIntentId: json['payment_intent_id']?.toString(),
      completedAt: json['completed_at']?.toString(),
      disputeDeadlineAt: json['dispute_deadline_at']?.toString(),
      payoutStatus: json['payout_status']?.toString(),
      payoutTransferId: json['payout_transfer_id']?.toString(),
      payoutReleasedAt: json['payout_released_at']?.toString(),
      vendorPayoutAmount: num.tryParse('${json['vendor_payout_amount']}'),
      securityDeposit: num.tryParse('${json['security_deposit']}'),
      depositRefundStatus: json['deposit_refund_status']?.toString(),
      depositRefundedAt: json['deposit_refunded_at']?.toString(),
      location: json['location']?.toString(),
      addressRevealed: isAddressRevealed(status),
      productName: json['product_name']?.toString(),
      productImage: json['product_image']?.toString(),
      role: json['role']?.toString(),
      counterpartyLabel: _counterpartyField(json, 'label'),
      counterpartyName: _counterpartyField(json, 'name'),
      counterpartyImage: _counterpartyField(json, 'profile_image'),
      nextAction: ReservationAction.fromJson(
        json['next_action'] is Map<String, dynamic>
            ? json['next_action']
            : json['next_action'] is Map
            ? Map<String, dynamic>.from(json['next_action'])
            : null,
      ),
      openDispute: openDisputeMap is Map<String, dynamic>
          ? OrderDispute.fromJson(openDisputeMap)
          : openDisputeMap is Map
          ? OrderDispute.fromJson(Map<String, dynamic>.from(openDisputeMap))
          : null,
      policy: json['policy'] is Map<String, dynamic>
          ? json['policy']
          : json['policy'] is Map
          ? Map<String, dynamic>.from(json['policy'])
          : null,
      paymentAmountDue: num.tryParse('${paymentDueMap?['amount_due']}'),
      paymentApplicationFees: num.tryParse('${paymentDueMap?['application_fees']}'),
      vendorStripeAccountId: paymentDueMap?['vendor_stripe_account_id']?.toString(),
      canUpdateHandoff: json['can_update_handoff'] == true,
    );
  }

  static String? _counterpartyField(Map<String, dynamic> json, String key) {
    final counterparty = json['counterparty'];
    if (counterparty is Map<String, dynamic>) {
      return counterparty[key]?.toString();
    }
    if (counterparty is Map) {
      return counterparty[key]?.toString();
    }
    return null;
  }

  int get counterpartyId {
    return role == 'earner' ? userId : vendorId;
  }
}

class ReservationActionItem {
  final int orderId;
  final String orderStatus;
  final ReservationAction nextAction;

  ReservationActionItem({
    required this.orderId,
    required this.orderStatus,
    required this.nextAction,
  });

  factory ReservationActionItem.fromJson(Map<String, dynamic> json) {
    return ReservationActionItem(
      orderId: json['order_id'] is int ? json['order_id'] : int.parse('${json['order_id']}'),
      orderStatus: json['order_status']?.toString() ?? '',
      nextAction: ReservationAction.fromJson(
        json['next_action'] is Map<String, dynamic>
            ? json['next_action']
            : json['next_action'] is Map
            ? Map<String, dynamic>.from(json['next_action'])
            : null,
      ),
    );
  }
}

/// Maps to `order_events`.
class OrderEvent {
  final int id;
  final int orderId;
  final int? actorUserId;
  final String? actorType;
  final String eventType;
  final String? previousStatus;
  final String? newStatus;
  final Map<String, dynamic>? payload;
  final String? idempotencyKey;
  final String? createdAt;

  OrderEvent({
    required this.id,
    required this.orderId,
    this.actorUserId,
    this.actorType,
    required this.eventType,
    this.previousStatus,
    this.newStatus,
    this.payload,
    this.idempotencyKey,
    this.createdAt,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      orderId: json['order_id'] is int ? json['order_id'] : int.parse('${json['order_id']}'),
      actorUserId: json['actor_user_id'] is int
          ? json['actor_user_id']
          : int.tryParse('${json['actor_user_id']}'),
      actorType: json['actor_type']?.toString(),
      eventType: json['event_type']?.toString() ?? '',
      previousStatus: json['previous_status']?.toString(),
      newStatus: json['new_status']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload']
          : json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'])
          : null,
      idempotencyKey: json['idempotency_key']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class OrderTimeline {
  final Map<String, dynamic> order;
  final List<OrderEvent> events;
  final List<OrderDispute> disputes;

  OrderTimeline({
    required this.order,
    required this.events,
    required this.disputes,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    final events = <OrderEvent>[];
    if (rawEvents is List) {
      for (final item in rawEvents) {
        if (item is Map<String, dynamic>) {
          events.add(OrderEvent.fromJson(item));
        } else if (item is Map) {
          events.add(OrderEvent.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawDisputes = json['disputes'];
    final disputes = <OrderDispute>[];
    if (rawDisputes is List) {
      for (final item in rawDisputes) {
        if (item is Map<String, dynamic>) {
          disputes.add(OrderDispute.fromJson(item));
        } else if (item is Map) {
          disputes.add(OrderDispute.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final orderMap = json['order'];
    return OrderTimeline(
      order: orderMap is Map<String, dynamic>
          ? orderMap
          : orderMap is Map
          ? Map<String, dynamic>.from(orderMap)
          : <String, dynamic>{},
      events: events,
      disputes: disputes,
    );
  }
}
