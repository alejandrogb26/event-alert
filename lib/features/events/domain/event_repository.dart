import 'models/calendar_event.dart';

/// Contrato de acceso a datos para [CalendarEvent].
abstract class EventRepository {
  /// Inserta o reemplaza un evento (upsert por id).
  Future<void> save(CalendarEvent event);

  Future<void> delete(String id);

  Future<CalendarEvent?> findById(String id);

  Future<List<CalendarEvent>> findAll();

  /// Devuelve los eventos cuyo [CalendarEvent.startDateTime] está entre [start] y [end] (ambos incluidos).
  Future<List<CalendarEvent>> findBetween(DateTime start, DateTime end);

  /// Devuelve los eventos cuyo [CalendarEvent.startDateTime] >= [from], ordenados ascendentemente.
  Future<List<CalendarEvent>> findFuture(DateTime from);
}
