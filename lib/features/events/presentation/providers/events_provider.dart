import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/alerts/presentation/providers/alerts_provider.dart'
    show databaseServiceProvider;
import '../../../../services/scheduling/scheduling_service.dart';
import '../../data/event_dao.dart';
import '../../data/event_repository_impl.dart';
import '../../domain/event_repository.dart';
import '../../domain/models/calendar_event.dart';

// ─────────────────────────────────────────────────────────────────
// Providers de infraestructura
// ─────────────────────────────────────────────────────────────────

final eventDaoProvider = Provider<EventDao>((ref) {
  return EventDao(ref.watch(databaseServiceProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(eventDaoProvider));
});

// ─────────────────────────────────────────────────────────────────
// Notifier principal
// ─────────────────────────────────────────────────────────────────

final eventsNotifierProvider =
    AsyncNotifierProvider<EventsNotifier, List<CalendarEvent>>(
      EventsNotifier.new,
    );

/// Gestiona la lista completa de eventos y expone operaciones CRUD.
///
/// Los eventos se ordenan por [CalendarEvent.startDateTime] ascendente (UTC).
///
/// Nota: se evita el nombre `update` porque Riverpod 3.x lo reserva
/// en AsyncNotifier con una firma distinta.
class EventsNotifier extends AsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() => _fetchSorted();

  EventRepository get _repo => ref.read(eventRepositoryProvider);
  SchedulingService get _scheduling => SchedulingService.instance;

  Future<List<CalendarEvent>> _fetchSorted() async {
    final events = await _repo.findAll();
    return [...events]
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  /// Persiste un nuevo evento y programa su notificación si procede.
  Future<void> createEvent(CalendarEvent event) async {
    await _repo.save(event);
    try {
      await _scheduling.scheduleEvent(event);
    } catch (e, st) {
      debugPrint(
        '[alarm-audit] error=$e\n'
        'stacktrace=$st',
      );
      debugPrint('[EventsNotifier] scheduleEvent failed: $e');
    }
    state = await AsyncValue.guard(_fetchSorted);
  }

  /// Actualiza un evento existente: cancela la notificación anterior y
  /// programa la nueva.
  // Nombre `editEvent` en lugar de `updateEvent` para evitar colisión con
  // AsyncNotifier.update(FutureOr<T> Function(T)) de Riverpod 3.x.
  Future<void> editEvent(CalendarEvent event) async {
    try {
      await _scheduling.cancelEvent(event);
    } catch (e, st) {
      debugPrint(
        '[alarm-audit] error=$e\n'
        'stacktrace=$st',
      );
      debugPrint('[EventsNotifier] cancelEvent failed: $e');
    }
    await _repo.save(event);
    try {
      await _scheduling.scheduleEvent(event);
    } catch (e, st) {
      debugPrint(
        '[alarm-audit] error=$e\n'
        'stacktrace=$st',
      );
      debugPrint('[EventsNotifier] scheduleEvent(edit) failed: $e');
    }
    state = await AsyncValue.guard(_fetchSorted);
  }

  /// Cancela la notificación del evento y lo elimina de la base de datos.
  Future<void> deleteEvent(String id) async {
    final events = state.asData?.value;
    final event = events?.where((e) => e.id == id).firstOrNull;
    if (event != null) {
      try {
        await _scheduling.cancelEvent(event);
      } catch (e) {
        debugPrint('[EventsNotifier] cancelEvent(delete) failed: $e');
      }
    }
    await _repo.delete(id);
    state = await AsyncValue.guard(_fetchSorted);
  }
}

// ─────────────────────────────────────────────────────────────────
// Función auxiliar pura (no es un provider)
// ─────────────────────────────────────────────────────────────────

/// Devuelve los eventos de [events] cuyo [CalendarEvent.startDateTime]
/// convertido a hora local corresponde al día local [day].
List<CalendarEvent> eventsForDay(List<CalendarEvent> events, DateTime day) {
  final startOfDay = DateTime(day.year, day.month, day.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return events.where((e) {
    final local = e.startDateTime.toLocal();
    return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
  }).toList();
}
