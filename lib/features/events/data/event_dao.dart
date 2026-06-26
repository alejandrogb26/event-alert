import 'package:sqflite/sqflite.dart';

import '../../../services/database/database_service.dart';
import '../domain/models/calendar_event.dart';

/// Acceso directo a la tabla `calendar_events` en SQLite.
class EventDao {
  EventDao(this._service);

  final DatabaseService _service;

  static const _table = 'calendar_events';

  /// Inserta o reemplaza el evento (upsert por primary key).
  Future<void> insert(CalendarEvent event) async {
    final db = await _service.database;
    await db.insert(
      _table,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza los campos de un evento existente identificado por su id.
  Future<void> update(CalendarEvent event) async {
    final db = await _service.database;
    await db.update(
      _table,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _service.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<CalendarEvent?> findById(String id) async {
    final db = await _service.database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CalendarEvent.fromMap(rows.first);
  }

  Future<List<CalendarEvent>> findAll() async {
    final db = await _service.database;
    final rows = await db.query(_table, orderBy: 'start_datetime ASC');
    return rows.map(CalendarEvent.fromMap).toList();
  }

  /// Devuelve los eventos cuyo start_datetime cae dentro del rango [start, end].
  Future<List<CalendarEvent>> findBetween(DateTime start, DateTime end) async {
    final db = await _service.database;
    final rows = await db.query(
      _table,
      where: 'start_datetime BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_datetime ASC',
    );
    return rows.map(CalendarEvent.fromMap).toList();
  }

  /// Devuelve los eventos con start_datetime >= [from].
  Future<List<CalendarEvent>> findFuture(DateTime from) async {
    final db = await _service.database;
    final rows = await db.query(
      _table,
      where: 'start_datetime >= ?',
      whereArgs: [from.millisecondsSinceEpoch],
      orderBy: 'start_datetime ASC',
    );
    return rows.map(CalendarEvent.fromMap).toList();
  }
}
