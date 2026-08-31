class OrderStatus {
  static const bookingRequested = 'BOOKING_REQUESTED';
  static const accepted = 'ACCEPTED';
  static const paymentConfirmed = 'PAYMENT_CONFIRMED';
  static const scheduledHandoff = 'SCHEDULED_HANDOFF';
  static const pickupInProgress = 'PICKUP_IN_PROGRESS';
  static const waitingPickupConfirmation = 'WAITING_PICKUP_CONFIRMATION';
  static const active = 'ACTIVE';
  static const scheduledReturn = 'SCHEDULED_RETURN';
  static const returnInProgress = 'RETURN_IN_PROGRESS';
  static const waitingReturnConfirmation = 'WAITING_RETURN_CONFIRMATION';
  static const completed = 'COMPLETED';
  static const disputeWindow24h = 'DISPUTE_WINDOW_24H';
  static const issueOpen = 'ISSUE_OPEN';
  static const underReview = 'UNDER_REVIEW';
  static const rejected = 'REJECTED';
  static const cancelled = 'CANCELLED';

  static const _pendingStatuses = {
    accepted,
    paymentConfirmed,
    scheduledHandoff,
    pickupInProgress,
    waitingPickupConfirmation,
    active,
    scheduledReturn,
    returnInProgress,
    waitingReturnConfirmation,
    issueOpen,
    underReview,
  };

  static const _completedStatuses = {
    completed,
  };

  static bool isDisputeWindow(String? status) {
    return normalize(status) == disputeWindow24h;
  }

  /// Vendor Active tab: in-progress rentals plus post-return dispute window.
  static bool isVendorActiveTab(String? status) {
    return isPending(status) || isDisputeWindow(status);
  }

  static String normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return bookingRequested;
    }
    if (trimmed == 'PAYOUT_RELEASED') {
      return completed;
    }
    return trimmed;
  }

  static bool isNewBooking(String? status) {
    return normalize(status) == bookingRequested;
  }

  static bool isPending(String? status) {
    return _pendingStatuses.contains(normalize(status));
  }

  static bool isCompleted(String? status) {
    return _completedStatuses.contains(normalize(status));
  }

  static bool isCancelled(String? status) {
    return normalize(status) == cancelled;
  }

  static bool isRejected(String? status) {
    return normalize(status) == rejected;
  }

  static bool isTerminal(String? status) {
    final normalized = normalize(status);
    return isCancelled(normalized) || isRejected(normalized) || isCompleted(normalized);
  }

  /// Renter orders that are still in the rental lifecycle (not finished, cancelled, or declined).
  static bool isRenterActive(String? status) {
    return !isTerminal(status);
  }

  /// Issue / no-show reporting is only meaningful after payment and handoff scheduling.
  static bool canReportIssueOrNoShow(String? status) {
    final normalized = normalize(status);
    return normalized != bookingRequested &&
        normalized != accepted &&
        normalized != rejected &&
        normalized != cancelled &&
        normalized != completed;
  }

  static bool isDeliveryTransport(String? transportType) {
    return transportType?.trim().toLowerCase() == 'delivery';
  }

  /// Delivery & retrieval: earner updates handoff. Pickup & return: renter updates handoff.
  static bool canUpdateHandoffStatus({
    required String? transportType,
    required String? role,
  }) {
    final normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole != 'renter' && normalizedRole != 'earner') return false;
    if (isDeliveryTransport(transportType)) {
      return normalizedRole == 'earner';
    }
    return normalizedRole == 'renter';
  }

  static String handoffWaitingMessage({
    required String? transportType,
  }) {
    if (isDeliveryTransport(transportType)) {
      return 'Waiting for the provider to share arrival updates.';
    }
    return 'Waiting for the renter to share arrival updates.';
  }

  static String handoffWaitingStatusMessage({
    required String? transportType,
    required String? handoffStatus,
  }) {
    if (handoffStatus == 'DELAYED') {
      return isDeliveryTransport(transportType)
          ? 'The provider reported a delay.'
          : 'The renter reported a delay.';
    }
    if (handoffStatus == 'ON_THE_WAY') {
      return isDeliveryTransport(transportType)
          ? 'The provider is on the way.'
          : 'The renter is on the way.';
    }
    return handoffWaitingMessage(transportType: transportType);
  }

  static bool showHandoffActionsOnReservation({
    required String? orderStatus,
    required String? handoffStatus,
    required String? transportType,
    required String? role,
    bool canUpdateHandoff = false,
  }) {
    if (!canUpdateHandoff &&
        !canUpdateHandoffStatus(transportType: transportType, role: role)) {
      return false;
    }
    final status = normalize(orderStatus);
    if (handoffStatus == 'DELAYED') return true;
    if (status != scheduledHandoff && status != scheduledReturn) return false;
    return handoffStatus != 'ARRIVED';
  }

  static bool showHandoffWaitingOnReservation({
    required String? orderStatus,
    required String? handoffStatus,
    required String? transportType,
    required String? role,
    bool canUpdateHandoff = false,
  }) {
    if (canUpdateHandoff ||
        canUpdateHandoffStatus(transportType: transportType, role: role)) {
      return false;
    }
    if (handoffStatus == 'ARRIVED') return false;
    final status = normalize(orderStatus);
    if (status == pickupInProgress ||
        status == returnInProgress ||
        status == waitingPickupConfirmation ||
        status == waitingReturnConfirmation) {
      return false;
    }
    if (handoffStatus == 'DELAYED') return true;
    if (status != scheduledHandoff && status != scheduledReturn) return false;
    return true;
  }

  /// True once the shared inspection record exists — not merely after handoff arrival.
  static bool showContinueInspectionLabel({
    required String? orderStatus,
    required bool hasStartedInspection,
  }) {
    final status = normalize(orderStatus);
    if (status == waitingPickupConfirmation || status == waitingReturnConfirmation) {
      return true;
    }
    if (status == pickupInProgress || status == returnInProgress) {
      return hasStartedInspection;
    }
    return false;
  }

  static bool handoffReadyForInspection({
    required String? orderStatus,
    required String? handoffStatus,
    required String phase,
  }) {
    if (handoffStatus == 'ARRIVED') return true;
    final status = normalize(orderStatus);
    if (phase == 'return') {
      return status == returnInProgress || status == waitingReturnConfirmation;
    }
    return status == pickupInProgress || status == waitingPickupConfirmation;
  }

  static String handoffPhaseForOrder(String? orderStatus, {String? handoffPhase}) {
    final normalizedPhase = handoffPhase?.trim().toLowerCase();
    if (normalizedPhase == 'return') return 'return';
    if (normalizedPhase == 'rental' || normalizedPhase == 'start') return 'pickup';
    return normalize(orderStatus) == scheduledReturn ? 'return' : 'pickup';
  }

  static String handoffStatusLabel(String? handoffStatus) {
    switch (handoffStatus) {
      case 'ON_THE_WAY':
        return 'On the way';
      case 'ARRIVED':
        return 'Arrived';
      case 'DELAYED':
        return 'Delayed';
      default:
        return 'Scheduled';
    }
  }

  /// Short badge for order list cards (renter / vendor My Orders).
  static String renterBadgeLabel(String? status) {
    final normalized = normalize(status);
    if (isRejected(normalized)) return 'REJECTED';
    if (isCancelled(normalized)) return 'CANCELLED';
    if (isCompleted(normalized)) return 'COMPLETED';
    return displayLabel(status).toUpperCase();
  }

  /// Human-readable label for reservation detail UI (e.g. `Scheduled handoff`).
  static String displayLabel(String? status) {
    switch (normalize(status)) {
      case active:
        return 'Active rental';
      case scheduledReturn:
        return 'Return scheduled';
      case scheduledHandoff:
        return 'Scheduled handoff';
      case waitingPickupConfirmation:
        return 'Waiting pickup confirmation';
      case waitingReturnConfirmation:
        return 'Waiting return confirmation';
      case pickupInProgress:
        return 'Pickup in progress';
      case returnInProgress:
        return 'Return in progress';
      case paymentConfirmed:
        return 'Payment confirmed';
      case bookingRequested:
        return 'Booking requested';
      case disputeWindow24h:
        return 'Dispute window';
      case completed:
        return 'Completed';
      case issueOpen:
        return 'Issue open';
      case underReview:
        return 'Under review';
      case rejected:
        return 'Declined by provider';
      case cancelled:
        return 'Cancelled';
      default:
        return normalize(status)
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  static String terminalStatusMessage(String? status) {
    final normalized = normalize(status);
    if (isRejected(normalized)) {
      return 'This booking was declined by the provider before payment was completed.';
    }
    if (isCancelled(normalized)) {
      return 'This reservation was cancelled and is no longer active.';
    }
    if (isCompleted(normalized)) {
      return 'This rental is complete. No further action is required.';
    }
    return '';
  }
}
