import '../../features/alerts/domain/models/recurrence_rule.dart';

// ─────────────────────────────────────────────────────────────────
// Cálculo de próxima ocurrencia
// ─────────────────────────────────────────────────────────────────

/// Devuelve la siguiente ocurrencia de [rule] con hora [timeMinutes]
/// estrictamente posterior a [from] (en hora local), o null si no existe.
///
/// [timeMinutes] son los minutos desde medianoche: 0 = 00:00, 570 = 09:30.
/// Todos los DateTime de entrada y salida son hora local.
///
/// TODO: maxOccurrences no se evalúa aquí porque requiere el historial
/// de disparos de la alerta (lastTriggeredAt + contador), que no es
/// responsabilidad de esta función pura.
DateTime? nextOccurrence({
  required RecurrenceRule rule,
  required int timeMinutes,
  required DateTime from,
}) {
  final hour = timeMinutes ~/ 60;
  final minute = timeMinutes % 60;

  DateTime? candidate;

  switch (rule.type) {
    case RecurrenceType.daily:
      candidate = _nextDaily(rule.interval, hour, minute, from);
    case RecurrenceType.weekly:
      candidate = _nextWeekly(
        rule.weekdays!,
        rule.interval,
        hour,
        minute,
        from,
      );
    case RecurrenceType.monthly:
      candidate = _nextMonthly(
        rule.dayOfMonth!,
        rule.interval,
        hour,
        minute,
        from,
      );
    case RecurrenceType.monthlyFirst:
      candidate = _nextMonthlyFirst(rule.interval, hour, minute, from);
  }

  if (candidate == null) return null;
  if (rule.endDate != null && candidate.isAfter(rule.endDate!)) return null;
  return candidate;
}

// ── Implementaciones privadas ──────────────────────────────────────

DateTime _nextDaily(int interval, int hour, int minute, DateTime from) {
  var candidate = DateTime(from.year, from.month, from.day, hour, minute);
  if (!candidate.isAfter(from)) {
    candidate = candidate.add(Duration(days: interval));
  }
  return candidate;
}

/// Busca el próximo día de la semana incluido en [weekdays] dentro de la
/// ventana [interval * 7] días desde [from].
///
/// Para interval > 1, la alineación de semanas no se puede garantizar sin
/// una fecha de inicio de la serie; se devuelve el primer día válido dentro
/// de la ventana, lo que es suficiente para el scheduling encadenado.
DateTime? _nextWeekly(
  List<int> weekdays,
  int interval,
  int hour,
  int minute,
  DateTime from,
) {
  final sorted = [...weekdays]..sort();
  final windowDays = interval * 7;

  for (var offset = 0; offset <= windowDays; offset++) {
    final date = DateTime(
      from.year,
      from.month,
      from.day,
    ).add(Duration(days: offset));
    if (sorted.contains(date.weekday)) {
      final candidate = DateTime(date.year, date.month, date.day, hour, minute);
      if (candidate.isAfter(from)) return candidate;
    }
  }
  return null;
}

/// Si el mes no tiene [dayOfMonth], usa el último día válido del mes.
/// Ej: día 31 en febrero → 28 o 29 según año.
DateTime? _nextMonthly(
  int dayOfMonth,
  int interval,
  int hour,
  int minute,
  DateTime from,
) {
  // Intentar en el mes actual
  var candidate = _clampedDay(from.year, from.month, dayOfMonth, hour, minute);
  if (candidate.isAfter(from)) return candidate;

  // Avanzar [interval] meses
  candidate = _clampedDay(
    from.year,
    from.month + interval,
    dayOfMonth,
    hour,
    minute,
  );
  return candidate;
}

DateTime? _nextMonthlyFirst(int interval, int hour, int minute, DateTime from) {
  // Primer día de este mes
  var candidate = DateTime(from.year, from.month, 1, hour, minute);
  if (candidate.isAfter(from)) return candidate;

  // Primer día del siguiente ciclo
  // DateTime maneja el desbordamiento de mes automáticamente
  candidate = DateTime(from.year, from.month + interval, 1, hour, minute);
  return candidate;
}

/// Construye un DateTime para [year]/[month]/[day], recortando [day] al
/// último día válido del mes si fuera necesario.
///
/// Dart maneja el desbordamiento de mes en DateTime, por lo que
/// DateTime(year, month + 1, 0) es siempre el último día del mes.
DateTime _clampedDay(int year, int month, int day, int hour, int minute) {
  final lastDay = DateTime(year, month + 1, 0).day;
  final validDay = day.clamp(1, lastDay);
  return DateTime(year, month, validDay, hour, minute);
}

// ─────────────────────────────────────────────────────────────────
// Texto humano
// ─────────────────────────────────────────────────────────────────

/// Convierte una regla de recurrencia y hora en texto legible en español.
///
/// Ejemplos:
/// - "Cada día a las 10:30"
/// - "Cada 2 días a las 08:00"
/// - "Cada lunes a las 09:00"
/// - "Cada lunes y miércoles a las 09:00"
/// - "Cada primer día del mes a las 13:00"
/// - "Cada día 15 del mes a las 13:00"
String recurrenceText(RecurrenceRule rule, int timeMinutes) {
  final t = _formatTime(timeMinutes);

  switch (rule.type) {
    case RecurrenceType.daily:
      if (rule.interval == 1) return 'Cada día a las $t';
      return 'Cada ${rule.interval} días a las $t';

    case RecurrenceType.weekly:
      final days = _weekdayNames(rule.weekdays ?? []);
      if (rule.interval == 1) return 'Cada $days a las $t';
      return 'Cada ${rule.interval} semanas, $days a las $t';

    case RecurrenceType.monthly:
      final day = rule.dayOfMonth ?? 1;
      if (rule.interval == 1) return 'Cada día $day del mes a las $t';
      return 'Cada ${rule.interval} meses, día $day a las $t';

    case RecurrenceType.monthlyFirst:
      if (rule.interval == 1) return 'Cada primer día del mes a las $t';
      return 'Cada ${rule.interval} meses, primer día a las $t';
  }
}

String _formatTime(int timeMinutes) {
  final h = (timeMinutes ~/ 60).toString().padLeft(2, '0');
  final m = (timeMinutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

const _weekdayLabels = {
  1: 'lunes',
  2: 'martes',
  3: 'miércoles',
  4: 'jueves',
  5: 'viernes',
  6: 'sábado',
  7: 'domingo',
};

String _weekdayNames(List<int> weekdays) {
  if (weekdays.isEmpty) return '(sin días)';
  final sorted = [...weekdays]..sort();
  final names = sorted.map((d) => _weekdayLabels[d]!).toList();
  if (names.length == 1) return names.first;
  if (names.length == 2) return '${names[0]} y ${names[1]}';
  return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}
