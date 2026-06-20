import '../domain/event_repository.dart';
import '../domain/models/calendar_event.dart';
import 'event_dao.dart';

/// Implementación de [EventRepository] que delega en [EventDao].
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._dao);

  final EventDao _dao;

  @override
  Future<void> save(CalendarEvent event) => _dao.insert(event);

  @override
  Future<void> delete(String id) => _dao.delete(id);

  @override
  Future<CalendarEvent?> findById(String id) => _dao.findById(id);

  @override
  Future<List<CalendarEvent>> findAll() => _dao.findAll();

  @override
  Future<List<CalendarEvent>> findBetween(DateTime start, DateTime end) =>
      _dao.findBetween(start, end);

  @override
  Future<List<CalendarEvent>> findFuture(DateTime from) =>
      _dao.findFuture(from);
}
