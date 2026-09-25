import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/domain/local_date.dart';

import 'helpers.dart';

void main() {
  group('LocalDate', () {
    test('parses and prints ISO dates', () {
      expect(d('2026-09-25').toIso(), '2026-09-25');
      expect(LocalDate.tryParse('2026-02-30'), isNull);
      expect(LocalDate.tryParse('09/25/2026'), isNull);
      expect(LocalDate.tryParse(null), isNull);
      expect(() => LocalDate.parse('2026-13-01'), throwsFormatException);
    });

    test('adds days across month, year and leap boundaries', () {
      expect(d('2026-01-31').addDays(1), d('2026-02-01'));
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2028-02-28').addDays(1), d('2028-02-29'));
      expect(d('2026-03-01').addDays(-1), d('2026-02-28'));
    });

    test('adding days is unaffected by US DST transitions', () {
      // DST starts 2026-03-08 and ends 2026-11-01 in the US.
      expect(d('2026-03-07').addDays(2), d('2026-03-09'));
      expect(d('2026-10-31').addDays(2), d('2026-11-02'));
      expect(d('2026-03-01').daysUntil(d('2026-03-15')), 14);
      expect(d('2026-10-25').daysUntil(d('2026-11-08')), 14);
    });

    test('Sunday–Saturday week helpers', () {
      // 2026-09-25 is a Friday.
      expect(d('2026-09-25').weekday, DateTime.friday);
      expect(d('2026-09-25').startOfWeekSunday, d('2026-09-20'));
      expect(d('2026-09-25').endOfWeekSaturday, d('2026-09-26'));
      // A Sunday is the start of its own week.
      expect(d('2026-09-20').startOfWeekSunday, d('2026-09-20'));
      // A Saturday is the end of its own week.
      expect(d('2026-09-26').endOfWeekSaturday, d('2026-09-26'));
    });

    test('ordering and equality', () {
      expect(d('2026-01-01').isBefore(d('2026-01-02')), isTrue);
      expect(d('2026-01-02') == d('2026-01-02'), isTrue);
      expect({d('2026-01-02'), d('2026-01-02')}.length, 1);
      expect(LocalDate.min(d('2026-01-02'), d('2025-01-02')), d('2025-01-02'));
    });
  });
}
