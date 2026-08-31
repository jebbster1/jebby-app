class HandoffWindow {
  final int? id;
  final String startTime;
  final String endTime;

  HandoffWindow({this.id, required this.startTime, required this.endTime});

  factory HandoffWindow.fromJson(Map<String, dynamic> json) {
    return HandoffWindow(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'start_time': startTime,
    'end_time': endTime,
  };

  static List<HandoffWindow> get defaultSlots => [
    HandoffWindow(startTime: '09:00:00', endTime: '12:00:00'),
  ];

  String get displayRange => '${formatClock(startTime)} - ${formatClock(endTime)}';

  String beginOnDate(String yyyyMmDd) => '$yyyyMmDd ${_normalizeTime(startTime)}';

  String endOnDate(String yyyyMmDd) => '$yyyyMmDd ${_normalizeTime(endTime)}';

  static String formatClock(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.padLeft(2, '0')} $period';
  }

  static String _normalizeTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '09:00:00';
    final parts = trimmed.split(':');
    if (parts.length >= 3) return trimmed;
    if (parts.length == 2) return '$trimmed:00';
    return '09:00:00';
  }
}
