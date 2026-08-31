import 'order_dispute.dart';

Map<String, dynamic>? _mapFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class InspectionChecklistItem {
  final String key;
  final String label;

  InspectionChecklistItem({required this.key, required this.label});

  factory InspectionChecklistItem.fromJson(Map<String, dynamic> json) {
    return InspectionChecklistItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

/// Maps to `order_inspection_checklist_responses`.
class OrderInspectionChecklistResponse {
  final int? id;
  final int? inspectionId;
  final String itemKey;
  final String response;
  final String? note;

  OrderInspectionChecklistResponse({
    this.id,
    this.inspectionId,
    required this.itemKey,
    required this.response,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'item_key': itemKey,
    'response': response,
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory OrderInspectionChecklistResponse.fromJson(Map<String, dynamic> json) {
    return OrderInspectionChecklistResponse(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.tryParse('${json['inspection_id']}'),
      itemKey: json['item_key']?.toString() ?? '',
      response: json['response']?.toString() ?? 'na',
      note: json['note']?.toString(),
    );
  }
}

typedef InspectionResponse = OrderInspectionChecklistResponse;

/// Maps to `order_inspections`.
class OrderInspection {
  final int id;
  final int orderId;
  final String phase;
  final String checklistVersion;
  final Map<String, dynamic>? checklistDraft;
  final String? lockedAt;
  final String? createdAt;

  OrderInspection({
    required this.id,
    required this.orderId,
    required this.phase,
    this.checklistVersion = 'v1',
    this.checklistDraft,
    this.lockedAt,
    this.createdAt,
  });

  bool get isLocked => lockedAt != null && lockedAt!.isNotEmpty;

  factory OrderInspection.fromJson(Map<String, dynamic> json) {
    return OrderInspection(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      orderId: json['order_id'] is int ? json['order_id'] : int.parse('${json['order_id']}'),
      phase: json['phase']?.toString() ?? 'pickup',
      checklistVersion: json['checklist_version']?.toString() ?? 'v1',
      checklistDraft: _mapFromJson(json['checklist_draft']),
      lockedAt: json['locked_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

/// Maps to `order_inspection_media`.
class OrderInspectionMedia {
  final int id;
  final int inspectionId;
  final int uploadedByUserId;
  final String filePath;
  final String? evidenceCategory;
  final Map<String, dynamic>? captureMetadata;
  final String? signedUrl;
  final String? createdAt;

  OrderInspectionMedia({
    required this.id,
    required this.inspectionId,
    required this.uploadedByUserId,
    required this.filePath,
    this.evidenceCategory,
    this.captureMetadata,
    this.signedUrl,
    this.createdAt,
  });

  factory OrderInspectionMedia.fromJson(Map<String, dynamic> json) {
    return OrderInspectionMedia(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.parse('${json['inspection_id']}'),
      uploadedByUserId: json['uploaded_by_user_id'] is int
          ? json['uploaded_by_user_id']
          : int.parse('${json['uploaded_by_user_id']}'),
      filePath: json['file_path']?.toString() ?? '',
      evidenceCategory: json['evidence_category']?.toString(),
      captureMetadata: _mapFromJson(json['capture_metadata']),
      signedUrl: json['signed_url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

/// Maps to `order_inspection_confirmations`.
class OrderInspectionConfirmation {
  final int id;
  final int inspectionId;
  final int userId;
  final String role;
  final String result;
  final String statementVersion;
  final String? createdAt;

  OrderInspectionConfirmation({
    required this.id,
    required this.inspectionId,
    required this.userId,
    required this.role,
    required this.result,
    this.statementVersion = 'v1',
    this.createdAt,
  });

  bool get isConfirmed => result == 'confirmed';

  factory OrderInspectionConfirmation.fromJson(Map<String, dynamic> json) {
    return OrderInspectionConfirmation(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      inspectionId: json['inspection_id'] is int
          ? json['inspection_id']
          : int.parse('${json['inspection_id']}'),
      userId: json['user_id'] is int ? json['user_id'] : int.parse('${json['user_id']}'),
      role: json['role']?.toString() ?? '',
      result: json['result']?.toString() ?? 'confirmed',
      statementVersion: json['statement_version']?.toString() ?? 'v1',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class TrustStatus {
  final int orderId;
  final String orderStatus;
  final String? phase;
  final String? role;
  final List<InspectionChecklistItem> checklistTemplate;
  final Map<String, dynamic>? policy;
  final OrderInspection? inspection;
  final List<OrderInspectionChecklistResponse> responses;
  final List<OrderInspectionMedia> media;
  final OrderInspectionConfirmation? myConfirmation;
  final OrderInspectionConfirmation? otherConfirmation;
  final OrderDisputeLite? openDispute;

  TrustStatus({
    required this.orderId,
    required this.orderStatus,
    this.phase,
    this.role,
    this.checklistTemplate = const [],
    this.policy,
    this.inspection,
    this.responses = const [],
    this.media = const [],
    this.myConfirmation,
    this.otherConfirmation,
    this.openDispute,
  });

  bool get bothConfirmed =>
      myConfirmation?.isConfirmed == true && otherConfirmation?.isConfirmed == true;

  factory TrustStatus.fromJson(Map<String, dynamic> json) {
    final template = <InspectionChecklistItem>[];
    final rawTemplate = json['checklist_template'];
    if (rawTemplate is List) {
      for (final item in rawTemplate) {
        final map = _mapFromJson(item);
        if (map != null) {
          template.add(InspectionChecklistItem.fromJson(map));
        }
      }
    }

    final rawResponses = json['responses'];
    final responses = <OrderInspectionChecklistResponse>[];
    if (rawResponses is List) {
      for (final item in rawResponses) {
        final map = _mapFromJson(item);
        if (map != null) {
          responses.add(OrderInspectionChecklistResponse.fromJson(map));
        }
      }
    }

    final rawMedia = json['media'];
    final media = <OrderInspectionMedia>[];
    if (rawMedia is List) {
      for (final item in rawMedia) {
        final map = _mapFromJson(item);
        if (map != null) {
          media.add(OrderInspectionMedia.fromJson(map));
        }
      }
    }

    final inspectionMap = _mapFromJson(json['inspection']);
    final myConfirmationMap = _mapFromJson(json['my_confirmation']);
    final otherConfirmationMap = _mapFromJson(json['other_confirmation']);
    final openDisputeMap = _mapFromJson(json['open_dispute']);

    return TrustStatus(
      orderId: json['order_id'] is int ? json['order_id'] : int.parse('${json['order_id']}'),
      orderStatus: json['order_status']?.toString() ?? '',
      phase: json['phase']?.toString(),
      role: json['role']?.toString(),
      checklistTemplate: template,
      policy: _mapFromJson(json['policy']),
      inspection: inspectionMap != null ? OrderInspection.fromJson(inspectionMap) : null,
      responses: responses,
      media: media,
      myConfirmation: myConfirmationMap != null
          ? OrderInspectionConfirmation.fromJson(myConfirmationMap)
          : null,
      otherConfirmation: otherConfirmationMap != null
          ? OrderInspectionConfirmation.fromJson(otherConfirmationMap)
          : null,
      openDispute: openDisputeMap != null ? OrderDisputeLite.fromJson(openDisputeMap) : null,
    );
  }
}
