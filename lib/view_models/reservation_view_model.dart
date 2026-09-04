import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/inspection.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';
import '../utils/order_status.dart';
import 'package:jebby/repositories/api_repository.dart';

class ReservationViewModel extends ChangeNotifier {
  ReservationViewModel({ReservationRepository? repository})
      : _repository = repository ?? ReservationRepository.instance;

  final ReservationRepository _repository;

  Reservation? reservation;
  TrustStatus? trustStatus;
  List<ReservationActionItem> actionItems = [];
  bool loading = false;
  bool paymentLoading = false;
  /// `'accept'` | `'decline'` while vendor booking action is in flight.
  String? bookingActionLoading;
  String? error;

  Future<void> loadReservation(int orderId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      reservation = await _repository.fetchReservation(orderId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadActionRequired() async {
    try {
      final items = await _repository.fetchActionRequired();
      actionItems = items
          .where((item) => !OrderStatus.isDisputeWindow(item.orderStatus))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadTrust(int orderId, {String? phase}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      trustStatus = await _repository.fetchTrustStatus(orderId, phase: phase);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> prefetchTrust(int orderId, {required String phase}) async {
    try {
      trustStatus = await _repository.fetchTrustStatus(orderId, phase: phase);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> acceptOrder(int orderId) async {
    bookingActionLoading = 'accept';
    error = null;
    notifyListeners();
    try {
      reservation = await _repository.acceptOrder(orderId);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      bookingActionLoading = null;
      notifyListeners();
    }
  }

  Future<bool> declineOrder(int orderId, {String? reason}) async {
    bookingActionLoading = 'decline';
    error = null;
    notifyListeners();
    try {
      reservation = await _repository.declineOrder(orderId, reason: reason);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      bookingActionLoading = null;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment(int orderId, String paymentIntentId) async {
    try {
      reservation = await _repository.confirmPayment(orderId, paymentIntentId);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> payForAcceptedOrder(Reservation reservation) async {
    final amount = reservation.paymentAmountDue;
    final vendorAccountId = reservation.vendorStripeAccountId;
    final applicationFees = reservation.paymentApplicationFees;
    if (amount == null || vendorAccountId == null || vendorAccountId.isEmpty) {
      error = 'Payment details are unavailable. Pull to refresh and try again.';
      notifyListeners();
      return false;
    }

    paymentLoading = true;
    error = null;
    notifyListeners();
    try {
      final ok = await ApiRepository.shared.payAcceptedOrder(
        orderId: reservation.id,
        userId: reservation.userId.toString(),
        amount: amount,
        vendorAccountId: vendorAccountId,
        applicationFees: applicationFees ?? 0,
      );
      if (ok) {
        await loadReservation(reservation.id);
      }
      return ok;
    } finally {
      paymentLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markOnTheWay(int orderId, int etaMinutes) async {
    try {
      reservation = await _repository.handoffOnTheWay(orderId, etaMinutes);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markArrived(int orderId) async {
    try {
      reservation = await _repository.handoffArrived(orderId);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> startInspection(int orderId, String phase) async {
    try {
      await _repository.startInspection(orderId, phase);
      await loadTrust(orderId, phase: phase);
      await loadReservation(orderId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveChecklist(
    int orderId,
    String phase,
    List<InspectionResponse> responses,
  ) async {
    try {
      await _repository.saveChecklistDraft(orderId, phase, responses);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmInspection(int orderId, String phase) async {
    error = null;
    try {
      await _repository.confirmInspection(orderId, phase);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }

    await prefetchTrust(orderId, phase: phase);
    try {
      reservation = await _repository.fetchReservation(orderId);
    } catch (_) {}
    notifyListeners();
    return true;
  }

  Future<bool> uploadInspectionPhoto(int orderId, String phase, File file) async {
    try {
      await _repository.uploadInspectionPhoto(orderId, phase, file);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportDispute(
    int orderId, {
    String? phase,
    required String category,
    required String description,
    bool otherPartyPresent = false,
    required List<File> photos,
  }) async {
    try {
      await _repository.reportDispute(
        orderId,
        phase: phase,
        category: category,
        description: description,
        otherPartyPresent: otherPartyPresent,
        photos: photos,
      );
      await loadReservation(orderId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
