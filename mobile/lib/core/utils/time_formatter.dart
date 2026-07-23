class TimeFormatter {
  static String format(String time24) {
    if (time24.isEmpty) return time24;
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    int? hour = int.tryParse(parts[0]);
    final minute = parts[1];
    if (hour == null) return time24;
    if (hour == 0) return '12:$minute ص';
    if (hour == 12) return '12:$minute م';
    if (hour < 12) return '$hour:$minute ص';
    return '${hour - 12}:$minute م';
  }
}
