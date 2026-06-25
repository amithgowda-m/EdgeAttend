// lib/core/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _full     = DateFormat('yyyy-MM-dd  HH:mm:ss');
  static final DateFormat _short    = DateFormat('HH:mm:ss');
  static final DateFormat _dateOnly = DateFormat('dd MMM yyyy');

  /// Full timestamp: "2024-01-15  14:30:22"
  static String full(DateTime dt) => _full.format(dt.toLocal());

  /// Time only: "14:30:22"
  static String timeOnly(DateTime dt) => _short.format(dt.toLocal());

  /// Date only: "15 Jan 2024"
  static String dateOnly(DateTime dt) => _dateOnly.format(dt.toLocal());

  /// Hour integer for grouping: 0–23
  static int hourOf(DateTime dt) => dt.toLocal().hour;

  /// Human-readable hour label: "14:00"
  static String hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  /// Relative label: "just now", "2m ago", "3h ago", "yesterday"
  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    == 1)  return 'yesterday';
    return _dateOnly.format(dt.toLocal());
  }
}
