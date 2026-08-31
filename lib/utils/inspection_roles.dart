/// Pickup: renter runs inspection. Return: earner runs inspection.
/// The other party reviews the shared record and confirms only.
class InspectionRoles {
  InspectionRoles._();

  static String initiatorRole(String phase) {
    return phase == 'return' ? 'earner' : 'renter';
  }

  static String reviewerRole(String phase) {
    return phase == 'return' ? 'renter' : 'earner';
  }

  static bool isInitiator(String phase, String? role) {
    return role?.trim().toLowerCase() == initiatorRole(phase);
  }

  static bool isReviewer(String phase, String? role) {
    return role?.trim().toLowerCase() == reviewerRole(phase);
  }

  static String waitingForInitiatorMessage(String phase) {
    if (phase == 'return') {
      return 'Waiting for the provider to complete the return inspection.';
    }
    return 'Waiting for the renter to complete the pickup inspection.';
  }

  static String waitingForInitiatorConfirmationMessage(String phase) {
    if (phase == 'return') {
      return 'Waiting for the provider to confirm acceptable condition.';
    }
    return 'Waiting for the renter to confirm acceptable condition.';
  }

  static String reviewSubtitle(String phase) {
    if (phase == 'return') {
      return 'Review the return checklist and photos, then confirm or report an issue.';
    }
    return 'Review the pickup checklist and photos, then confirm or report an issue.';
  }
}
