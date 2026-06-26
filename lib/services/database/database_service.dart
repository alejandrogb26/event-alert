import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton que gestiona la conexión SQLite y el ciclo de vida del schema.
///
/// Acceso:  `final db = await DatabaseService.instance.database;`
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  /// Devuelve la base de datos abierta, inicializándola la primera vez.
  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'event_alert.db');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alerts (
        id                TEXT    PRIMARY KEY,
        title             TEXT    NOT NULL,
        description       TEXT,
        time_minutes      INTEGER NOT NULL,
        recurrence        TEXT    NOT NULL,
        notification_config TEXT  NOT NULL,
        alarm_config      TEXT    NOT NULL,
        is_active         INTEGER NOT NULL DEFAULT 1,
        created_at        INTEGER NOT NULL,
        last_triggered_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE calendar_events (
        id                TEXT    PRIMARY KEY,
        title             TEXT    NOT NULL,
        description       TEXT,
        start_datetime    INTEGER NOT NULL,
        duration_ms       INTEGER,
        notification_config TEXT  NOT NULL,
        alarm_config      TEXT    NOT NULL,
        created_at        INTEGER NOT NULL
      )
    ''');

    // Índice para consultas de eventos por rango de fechas.
    await db.execute('''
      CREATE INDEX idx_events_start_datetime
      ON calendar_events(start_datetime)
    ''');

    // Índice para filtrar alertas activas eficientemente.
    await db.execute('''
      CREATE INDEX idx_alerts_is_active
      ON alerts(is_active)
    ''');
  }

  /// Cierra la conexión. Útil en tests o en flujos de limpieza.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
