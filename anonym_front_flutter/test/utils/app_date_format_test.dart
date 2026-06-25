import 'package:anonym_front_flutter/utils/app_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateFormat.shortDate', () {
    test('formats date as dd/mm/yyyy', () {
      final formatted = AppDateFormat.shortDate(DateTime(2026, 5, 2));
      expect(formatted, '02/05/2026');
    });

    test('returns dash for null date', () {
      expect(AppDateFormat.shortDate(null), '-');
    });
  });

  group('AppDateFormat.shortDateTime', () {
    test('formats date and time', () {
      final formatted = AppDateFormat.shortDateTime(DateTime(2026, 5, 2, 7, 5));
      expect(formatted, '02/05/2026 07:05');
    });

    test('returns dash for null date', () {
      expect(AppDateFormat.shortDateTime(null), '-');
    });
  });

  group('AppDateFormat.shortTime', () {
    test('formats time as HH:mm', () {
      final formatted = AppDateFormat.shortTime(DateTime(2026, 5, 2, 8, 9));
      expect(formatted, '08:09');
    });

    test('returns placeholder for null date', () {
      expect(AppDateFormat.shortTime(null), '--:--');
    });
  });

  group('AppDateFormat.daysAgo', () {
    test('returns dash for null date', () {
      expect(AppDateFormat.daysAgo(null), '-');
    });

    test('returns 1 day for future date', () {
      final formatted = AppDateFormat.daysAgo(
        DateTime.now().add(const Duration(days: 2)),
      );
      expect(formatted, '1 jours');
    });

    test('returns expected day count for past date', () {
      final formatted = AppDateFormat.daysAgo(
        DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      );
      expect(formatted, '3 jours');
    });
  });

  test('longDate can be called safely', () {
    AppDateFormat.longDate(null);
  });
}
