// Sentinel que distingue "no proporcionado" de null explícito en copyWith.
const _absent = Object();

enum RecurrenceType { daily, weekly, monthly, monthlyFirst }

class RecurrenceRule {
  const RecurrenceRule._({
    required this.type,
    required this.interval,
    this.weekdays,
    this.dayOfMonth,
    this.endDate,
    this.maxOccurrences,
  });

  factory RecurrenceRule({
    required RecurrenceType type,
    int interval = 1,
    List<int>? weekdays,
    int? dayOfMonth,
    DateTime? endDate,
    int? maxOccurrences,
  }) {
    assert(interval >= 1, 'interval debe ser >= 1');
    assert(
      weekdays == null || weekdays.every((d) => d >= 1 && d <= 7),
      'weekdays debe contener valores entre 1 (lunes) y 7 (domingo)',
    );
    assert(
      dayOfMonth == null || (dayOfMonth >= 1 && dayOfMonth <= 31),
      'dayOfMonth debe estar entre 1 y 31',
    );
    assert(
      type != RecurrenceType.weekly ||
          (weekdays != null && weekdays.isNotEmpty),
      'Para recurrencia semanal, weekdays no puede ser nulo ni vacío',
    );
    assert(
      type != RecurrenceType.monthly || dayOfMonth != null,
      'Para recurrencia mensual, dayOfMonth es obligatorio',
    );
    return RecurrenceRule._(
      type: type,
      interval: interval,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
      endDate: endDate,
      maxOccurrences: maxOccurrences,
    );
  }

  final RecurrenceType type;

  /// Cada cuántas unidades del tipo se repite. Mínimo 1.
  final int interval;

  /// Días de la semana activos. 1 = lunes, 7 = domingo. Solo para [RecurrenceType.weekly].
  final List<int>? weekdays;

  /// Día del mes (1–31). Solo para [RecurrenceType.monthly].
  final int? dayOfMonth;

  /// Fecha límite de la recurrencia. null = sin fecha fin.
  final DateTime? endDate;

  /// Número máximo de ocurrencias. null = sin límite.
  final int? maxOccurrences;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'interval': interval,
    if (weekdays != null) 'weekdays': weekdays,
    if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
    if (endDate != null) 'endDate': endDate!.millisecondsSinceEpoch,
    if (maxOccurrences != null) 'maxOccurrences': maxOccurrences,
  };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    type: RecurrenceType.values.byName(json['type'] as String),
    interval: json['interval'] as int? ?? 1,
    weekdays: (json['weekdays'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(),
    dayOfMonth: json['dayOfMonth'] as int?,
    endDate: json['endDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int)
        : null,
    maxOccurrences: json['maxOccurrences'] as int?,
  );

  RecurrenceRule copyWith({
    RecurrenceType? type,
    int? interval,
    Object? weekdays = _absent,
    Object? dayOfMonth = _absent,
    Object? endDate = _absent,
    Object? maxOccurrences = _absent,
  }) => RecurrenceRule(
    type: type ?? this.type,
    interval: interval ?? this.interval,
    weekdays: identical(weekdays, _absent)
        ? this.weekdays
        : weekdays as List<int>?,
    dayOfMonth: identical(dayOfMonth, _absent)
        ? this.dayOfMonth
        : dayOfMonth as int?,
    endDate: identical(endDate, _absent) ? this.endDate : endDate as DateTime?,
    maxOccurrences: identical(maxOccurrences, _absent)
        ? this.maxOccurrences
        : maxOccurrences as int?,
  );

  @override
  String toString() =>
      'RecurrenceRule(type: $type, interval: $interval, '
      'weekdays: $weekdays, dayOfMonth: $dayOfMonth, '
      'endDate: $endDate, maxOccurrences: $maxOccurrences)';
}
