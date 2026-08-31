import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../model/inspection.dart';
import '../model/reservation.dart';
import '../res/app_url.dart';
import '../utils/api_headers.dart';

class ReservationRepository {
  ReservationRepository._();
  static final ReservationRepository instance = ReservationRepository._();
  final _uuid = const Uuid();

  Future<Map<String, String>> _headers({bool idempotent = false}) async {
    final headers = await ApiHeaders.json();
    if (idempotent) {
      headers['Idempotency-Key'] = _uuid.v4();
    }
    return headers;
  }

  Future<Reservation> fetchReservation(int orderId) async {
    final response = await http.get(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId'),
      headers: await _headers(),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to load reservation');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<List<ReservationActionItem>> fetchActionRequired() async {
    final response = await http.get(
      Uri.parse(AppUrl.reservationsActionRequired),
      headers: await _headers(),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      return [];
    }
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((item) => ReservationActionItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Reservation> acceptOrder(int orderId) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/accept'),
      headers: await _headers(idempotent: true),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Accept failed');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Reservation> declineOrder(int orderId, {String? reason}) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/decline'),
      headers: await _headers(idempotent: true),
      body: json.encode({
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Decline failed');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Reservation> confirmPayment(int orderId, String paymentIntentId) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/payment-confirmed'),
      headers: await _headers(idempotent: true),
      body: json.encode({'payment_intent_id': paymentIntentId}),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Payment confirmation failed');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Reservation> handoffOnTheWay(int orderId, int etaMinutes) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/handoff/on-the-way'),
      headers: await _headers(idempotent: true),
      body: json.encode({'eta_minutes': etaMinutes}),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to update handoff');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<Reservation> handoffArrived(int orderId) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/handoff/arrived'),
      headers: await _headers(idempotent: true),
    );
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to record arrival');
    }
    return Reservation.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<TrustStatus> fetchTrustStatus(int orderId, {String? phase}) async {
    final path = phase == null
        ? '${AppUrl.baseUrlM}/orders/$orderId/trust'
        : '${AppUrl.baseUrlM}/orders/$orderId/trust/$phase';
    final response = await http.get(Uri.parse(path), headers: await _headers());
    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Failed to load trust status');
    }
    return TrustStatus.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<void> startInspection(int orderId, String phase) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/inspections/$phase/start'),
      headers: await _headers(idempotent: true),
    );
    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to start inspection');
    }
  }

  Future<void> saveChecklistDraft(
    int orderId,
    String phase,
    List<InspectionResponse> responses,
  ) async {
    final response = await http.put(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/inspections/$phase/checklist'),
      headers: await _headers(),
      body: json.encode({
        'responses': responses.map((r) => r.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to save checklist');
    }
  }

  Future<void> confirmInspection(int orderId, String phase, {String result = 'confirmed'}) async {
    final response = await http.post(
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/inspections/$phase/confirm'),
      headers: await _headers(idempotent: true),
      body: json.encode({'result': result}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to confirm inspection');
    }
  }

  Future<void> uploadInspectionPhoto(
    int orderId,
    String phase,
    File file, {
    String evidenceCategory = 'general',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/inspections/$phase/media'),
    );
    request.headers.addAll(await _headers(idempotent: true));
    request.fields['evidence_category'] = evidenceCategory;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to upload photo');
    }
  }

  Future<void> reportDispute(
    int orderId, {
    String? phase,
    required String category,
    required String description,
    bool otherPartyPresent = false,
    required List<File> photos,
  }) async {
    if (photos.isEmpty) {
      throw Exception('At least one photo is required.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppUrl.baseUrlM}/orders/$orderId/disputes'),
    );
    request.headers.addAll(await _headers(idempotent: true));
    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['other_party_present'] = otherPartyPresent ? 'true' : 'false';
    if (phase != null) {
      request.fields['phase'] = phase;
    }
    for (final photo in photos) {
      request.files.add(await http.MultipartFile.fromPath('files', photo.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to report issue');
    }
  }
}
