import 'package:event_alert/core/utils/recurrence_calculator.dart';
import 'package:event_alert/features/alerts/domain/models/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextOccurrence daily', () {
    test('returns today when the alert time is still in the future', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.daily),
        timeMinutes: 10 * 60 + 30,
        from: DateTime(2024, 1, 10, 9),
      );

      expect(next, DateTime(2024, 1, 10, 10, 30));
    });

    test('returns tomorrow when the alert time already passed today', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.daily),
        timeMinutes: 10 * 60 + 30,
        from: DateTime(2024, 1, 10, 11),
      );

      expect(next, DateTime(2024, 1, 11, 10, 30));
    });

    test('respects a 2 day interval after today already passed', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.daily, interval: 2),
        timeMinutes: 10 * 60 + 30,
        from: DateTime(2024, 1, 10, 11),
      );

      expect(next, DateTime(2024, 1, 12, 10, 30));
    });
  });

  group('nextOccurrence weekly', () {
    test('returns a single weekday occurrence', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(
          type: RecurrenceType.weekly,
          weekdays: [DateTime.monday],
        ),
        timeMinutes: 9 * 60,
        from: DateTime(2024, 1, 9, 8), // Tuesday.
      );

      expect(next, DateTime(2024, 1, 15, 9));
    });

    test('returns the next matching day for Monday and Wednesday', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(
          type: RecurrenceType.weekly,
          weekdays: [DateTime.monday, DateTime.wednesday],
        ),
        timeMinutes: 9 * 60,
        from: DateTime(2024, 1, 9, 8), // Tuesday.
      );

      expect(next, DateTime(2024, 1, 10, 9));
    });

    test('skips to the next week when today matches but the time passed', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(
          type: RecurrenceType.weekly,
          weekdays: [DateTime.monday],
        ),
        timeMinutes: 9 * 60,
        from: DateTime(2024, 1, 8, 10), // Monday.
      );

      expect(next, DateTime(2024, 1, 15, 9));
    });

    test('uses the interval as the search window for multi-week rules', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 2,
          weekdays: [DateTime.monday],
        ),
        timeMinutes: 9 * 60,
        from: DateTime(2024, 1, 8, 10), // Monday.
      );

      expect(next, DateTime(2024, 1, 15, 9));
    });
  });

  group('nextOccurrence monthly', () {
    test('returns day 15 of the current month when still in the future', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.monthly, dayOfMonth: 15),
        timeMinutes: 8 * 60,
        from: DateTime(2024, 1, 10, 9),
      );

      expect(next, DateTime(2024, 1, 15, 8));
    });

    test('clamps day 31 to day 30 in months with 30 days', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.monthly, dayOfMonth: 31),
        timeMinutes: 8 * 60,
        from: DateTime(2024, 4, 1),
      );

      expect(next, DateTime(2024, 4, 30, 8));
    });

    test('clamps day 31 to February 28 in a non-leap year', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.monthly, dayOfMonth: 31),
        timeMinutes: 8 * 60,
        from: DateTime(2023, 2, 1),
      );

      expect(next, DateTime(2023, 2, 28, 8));
    });

    test('clamps day 31 to February 29 in a leap year', () {
      final next = nextOccurrence(
        rule: RecurrenceRule(type: RecurrenceType.monthly, dayOfMonth: 31),
        timeMinutes: 8 * 60,
        from: DateTime(2024, 2, 1),
      );

      expect(next, DateTime(2024, 2, 29, 8));
    });
  });

  group('nextOccurrence monthlyFirst', () {
    test(
      'returns the first day of the next month when current month passed',
      () {
        final next = nextOccurrence(
          rule: RecurrenceRule(type: RecurrenceType.monthlyFirst),
          timeMinutes: 13 * 60,
          from: DateTime(2024, 1, 15),
        );

        expect(next, DateTime(2024, 2, 1, 13));
      },
    );
  });

  group('nextOccurrence endDate', () {
    test(
      'returns null when no valid occurrence exists before the end date',
      () {
        final next = nextOccurrence(
          rule: RecurrenceRule(
            type: RecurrenceType.daily,
            endDate: DateTime(2024, 1, 11),
          ),
          timeMinutes: 10 * 60 + 30,
          from: DateTime(2024, 1, 10, 11),
        );

        expect(next, isNull);
      },
    );
  });

  group('recurrenceText', () {
    test('formats daily text', () {
      expect(
        recurrenceText(
          RecurrenceRule(type: RecurrenceType.daily),
          10 * 60 + 30,
        ),
        'Cada día a las 10:30',
      );
    });

    test('formats daily interval text', () {
      expect(
        recurrenceText(
          RecurrenceRule(type: RecurrenceType.daily, interval: 2),
          10 * 60 + 30,
        ),
        'Cada 2 días a las 10:30',
      );
    });

    test('formats a single weekly day', () {
      expect(
        recurrenceText(
          RecurrenceRule(
            type: RecurrenceType.weekly,
            weekdays: [DateTime.monday],
          ),
          9 * 60,
        ),
        'Cada lunes a las 09:00',
      );
    });

    test('formats two weekly days', () {
      expect(
        recurrenceText(
          RecurrenceRule(
            type: RecurrenceType.weekly,
            weekdays: [DateTime.monday, DateTime.wednesday],
          ),
          9 * 60,
        ),
        'Cada lunes y miércoles a las 09:00',
      );
    });

    test('formats first day of month', () {
      expect(
        recurrenceText(
          RecurrenceRule(type: RecurrenceType.monthlyFirst),
          13 * 60,
        ),
        'Cada primer día del mes a las 13:00',
      );
    });

    test('formats day 15 of month', () {
      expect(
        recurrenceText(
          RecurrenceRule(type: RecurrenceType.monthly, dayOfMonth: 15),
          13 * 60,
        ),
        'Cada día 15 del mes a las 13:00',
      );
    });
  });
}
