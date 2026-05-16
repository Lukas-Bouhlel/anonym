class AppDateFormat {
  const AppDateFormat._();

  static String shortDate(DateTime? date) {
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  static String shortDateTime(DateTime? date) {
    if (date == null) return '-';
    final base = shortDate(date);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$base $hour:$minute';
  }

  static String shortTime(DateTime? date) {
    if (date == null) return '--:--';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String daysAgo(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    final safeDiff = diff <= 0 ? 1 : diff;
    return '$safeDiff jours';
  }
}
