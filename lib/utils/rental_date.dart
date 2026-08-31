import 'package:intl/intl.dart';

import 'api_datetime.dart';

/// Parses API/DB rental date values (`DATE` columns serialize as `yyyy-MM-dd` or ISO).
String? parseRentalDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
    return raw.substring(0, 10);
  }
  try {
    return DateFormat('yyyy-MM-dd').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

DateTime? rentalDateToDateTime(String? value) {
  final normalized = parseRentalDate(value);
  if (normalized == null) return null;
  return DateTime.parse(normalized);
}

String formatRentalDateForDisplay(String? value, {String pattern = 'd/M/yyyy'}) {
  final dt = rentalDateToDateTime(value);
  if (dt == null) return value?.trim().isNotEmpty == true ? value! : '—';
  return DateFormat(pattern).format(dt);
}

String _clockFromWindowPart(String raw) {
  final timePart = raw.contains(' ') ? raw.split(' ').last : raw;
  final normalized = timePart.split('.').first;
  final parts = normalized.split(':');
  if (parts.length < 2) return normalized;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${minute.padLeft(2, '0')} $period';
}

/// Formats API handoff window values (ISO or `yyyy-MM-dd HH:mm:ss`) for display.
String formatHandoffWindowRange(String? begin, String? end) {
  final beginText = begin?.trim() ?? '';
  final endText = end?.trim() ?? '';
  if (beginText.isEmpty || endText.isEmpty) return '—';

  DateTime? beginDt = parseApiDateTime(beginText);
  DateTime? endDt = parseApiDateTime(endText);

  if (beginDt != null && endDt != null) {
    final date = DateFormat('M/d/yyyy').format(beginDt);
    final start = DateFormat('h:mm a').format(beginDt);
    final finish = DateFormat('h:mm a').format(endDt);
    return '$date · $start – $finish';
  }

  final datePart = beginText.contains(' ') ? beginText.split(' ').first : beginText;
  final date = formatRentalDateForDisplay(datePart, pattern: 'M/d/yyyy');
  return '$date · ${_clockFromWindowPart(beginText)} – ${_clockFromWindowPart(endText)}';
}

class RentalWindow {
  final int orderId;
  final String? productName;
  final String? startDate;
  final String? endDate;

  const RentalWindow({
    required this.orderId,
    this.productName,
    this.startDate,
    this.endDate,
  });
}

bool rentalRangesOverlap(String? startA, String? endA, String? startB, String? endB) {
  final aStart = rentalDateToDateTime(startA);
  final aEnd = rentalDateToDateTime(endA);
  final bStart = rentalDateToDateTime(startB);
  final bEnd = rentalDateToDateTime(endB);
  if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
    return false;
  }
  return !aStart.isAfter(bEnd) && !aEnd.isBefore(bStart);
}

RentalWindow? findOverlappingRentalOrder({
  required String newStart,
  required String newEnd,
  required Iterable<RentalWindow> existingOrders,
}) {
  for (final order in existingOrders) {
    if (rentalRangesOverlap(newStart, newEnd, order.startDate, order.endDate)) {
      return order;
    }
  }
  return null;
}

bool isDayInBookedRange(DateTime day, Iterable<RentalWindow> booked) {
  final normalized = DateTime(day.year, day.month, day.day);
  for (final window in booked) {
    final start = rentalDateToDateTime(window.startDate);
    final end = rentalDateToDateTime(window.endDate);
    if (start == null || end == null) continue;
    if (!normalized.isBefore(start) && !normalized.isAfter(end)) return true;
  }
  return false;
}

/// True when a listing has at least one bookable calendar day on or after today.
bool productHasFutureBookableDates(String? availableFrom, String? availableTo) {
  final end = rentalDateToDateTime(availableTo);
  final start = rentalDateToDateTime(availableFrom);
  if (end == null || start == null) return false;
  if (start.isAfter(end)) return false;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (end.isBefore(today)) return false;

  final effectiveStart = start.isBefore(today) ? today : start;
  return !effectiveStart.isAfter(end);
}
