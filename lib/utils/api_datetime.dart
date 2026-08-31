import 'package:intl/intl.dart';

/// Parses API/MySQL datetimes as UTC and returns device-local time for display.
///
/// Backend stores audit timestamps in UTC. Values may arrive as ISO (`...Z`)
/// or MySQL-style (`yyyy-MM-dd HH:mm:ss`) without a timezone suffix.
DateTime? parseApiDateTime(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  var normalized = trimmed.replaceFirst(' ', 'T');
  if (!normalized.endsWith('Z') &&
      !RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(normalized)) {
    normalized = '${normalized}Z';
  }

  try {
    return DateTime.parse(normalized).toLocal();
  } catch (_) {
    return null;
  }
}

String formatApiTime(String? raw, {String pattern = 'hh:mm a'}) {
  final local = parseApiDateTime(raw);
  if (local == null) return '';
  return DateFormat(pattern).format(local);
}

String formatApiDate(String? raw, {String pattern = 'yyyy-MM-dd'}) {
  final local = parseApiDateTime(raw);
  if (local == null) return '';
  return DateFormat(pattern).format(local);
}
