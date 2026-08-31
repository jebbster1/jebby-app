class OrderDispute {
  final int id;
  final int orderId;
  final int? inspectionId;
  final int reportedBy;
  final String category;
  final String description;
  final bool otherPartyPresent;
  final String reviewStatus;
  final String? resolutionNote;
  final String? createdAt;
  final String? resolvedAt;

  OrderDispute({
    required this.id,
    required this.orderId,
    this.inspectionId,
    required this.reportedBy,
    required this.category,
    required this.description,
    this.otherPartyPresent = false,
    required this.reviewStatus,
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => reviewStatus == 'open' || reviewStatus == 'under_review';

  factory OrderDispute.fromJson(Map<String, dynamic> json) {
    return OrderDispute(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      orderId: json['order_id'] is int ? json['order_id'] : int.parse('${json['order_id']}'),
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.tryParse('${json['inspection_id']}'),
      reportedBy: json['reported_by'] is int
          ? json['reported_by']
          : int.parse('${json['reported_by']}'),
      category: json['category']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
      otherPartyPresent: json['other_party_present'] == true ||
          json['other_party_present'] == 1 ||
          json['other_party_present']?.toString() == '1',
      reviewStatus: json['review_status']?.toString() ?? 'open',
      resolutionNote: json['resolution_note']?.toString(),
      createdAt: json['created_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
    );
  }
}

class OrderDisputeLite {
  final int id;
  final String category;
  final String reviewStatus;

  OrderDisputeLite({
    required this.id,
    required this.category,
    required this.reviewStatus,
  });

  factory OrderDisputeLite.fromJson(Map<String, dynamic> json) {
    return OrderDisputeLite(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      category: json['category']?.toString() ?? 'other',
      reviewStatus: json['review_status']?.toString() ?? 'open',
    );
  }

  factory OrderDisputeLite.fromOrderDispute(OrderDispute dispute) {
    return OrderDisputeLite(
      id: dispute.id,
      category: dispute.category,
      reviewStatus: dispute.reviewStatus,
    );
  }
}
