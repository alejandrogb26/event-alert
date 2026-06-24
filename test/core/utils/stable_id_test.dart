import 'package:event_alert/core/utils/stable_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stableId', () {
    test('returns the same ID for the same input', () {
      const input = 'event:123e4567-e89b-12d3-a456-426614174000';

      expect(stableId(input), stableId(input));
      expect(stableId(input), 1122983281);
    });

    test('uses the namespace so event and alert IDs differ', () {
      const uuid = '123e4567-e89b-12d3-a456-426614174000';

      expect(stableId('event:$uuid'), isNot(stableId('alert:$uuid')));
      expect(stableId('alert:$uuid'), 535362099);
    });

    test('returns a positive Android notification ID', () {
      final id = stableId('daily:10:30');

      expect(id, greaterThan(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
      expect(id, 2005332782);
    });
  });
}
