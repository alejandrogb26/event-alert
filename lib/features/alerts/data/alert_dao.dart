import 'package:sqflite/sqflite.dart';

import '../../../services/database/database_service.dart';
import '../domain/models/alert.dart';

/// Acceso directo a la tabla `alerts` en SQLite.
///
/// Recibe [DatabaseService] en lugar de [Database] directamente para
/// no obligar al creador a resolver el Future antes de construir el DAO.
class AlertDao {
  AlertDao(this._service);

  final DatabaseService _service;

  static const _table = 'alerts';

  /// Inserta o reemplaza la alerta (upsert por primary key).
  Future<void> insert(Alert alert) async {
    final db = await _service.database;
    await db.insert(
      _table,
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza los campos de una alerta existente identificada por su id.
  Future<void> update(Alert alert) async {
    final db = await _service.database;
    await db.update(
      _table,
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _service.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<Alert?> findById(String id) async {
    final db = await _service.database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Alert.fromMap(rows.first);
  }

  Future<List<Alert>> findAll() async {
    final db = await _service.database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(Alert.fromMap).toList();
  }

  /// Devuelve solo las alertas con is_active = 1.
  Future<List<Alert>> findActive() async {
    final db = await _service.database;
    final rows = await db.query(
      _table,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return rows.map(Alert.fromMap).toList();
  }
}
