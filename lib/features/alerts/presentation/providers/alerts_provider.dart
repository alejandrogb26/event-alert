import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/database/database_service.dart';
import '../../../../services/scheduling/scheduling_service.dart';
import '../../data/alert_dao.dart';
import '../../data/alert_repository_impl.dart';
import '../../domain/alert_repository.dart';
import '../../domain/models/alert.dart';

// ─────────────────────────────────────────────────────────────────
// Providers de infraestructura
// ─────────────────────────────────────────────────────────────────

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

final alertDaoProvider = Provider<AlertDao>((ref) {
  return AlertDao(ref.watch(databaseServiceProvider));
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepositoryImpl(ref.watch(alertDaoProvider));
});

// ─────────────────────────────────────────────────────────────────
// Notifier principal
// ─────────────────────────────────────────────────────────────────

final alertsNotifierProvider =
    AsyncNotifierProvider<AlertsNotifier, List<Alert>>(AlertsNotifier.new);

/// Gestiona el estado de la lista de alertas y expone operaciones CRUD.
///
/// Orden: activas primero, luego inactivas; dentro de cada grupo,
/// por hora ascendente (timeMinutes).
///
/// Nota: se evita el nombre `update` porque Riverpod 3.x lo reserva
/// en AsyncNotifier con una firma distinta.
class AlertsNotifier extends AsyncNotifier<List<Alert>> {
  @override
  Future<List<Alert>> build() => _fetchSorted();

  AlertRepository get _repo => ref.read(alertRepositoryProvider);
  SchedulingService get _scheduling => SchedulingService.instance;

  Future<List<Alert>> _fetchSorted() async {
    final alerts = await _repo.findAll();
    return [...alerts]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.timeMinutes.compareTo(b.timeMinutes);
      });
  }

  /// Persiste una nueva alerta y programa su próxima notificación.
  Future<void> create(Alert alert) async {
    await _repo.save(alert);
    try {
      await _scheduling.scheduleAlert(alert);
    } catch (e) {
      debugPrint('[AlertsNotifier] scheduleAlert failed: $e');
    }
    state = await AsyncValue.guard(_fetchSorted);
  }

  /// Actualiza una alerta existente, cancela la notificación anterior y
  /// programa la nueva.
  // Nombre `edit` en lugar de `update` para evitar colisión con
  // AsyncNotifier.update(FutureOr<T> Function(T)) de Riverpod 3.x.
  Future<void> edit(Alert alert) async {
    try {
      await _scheduling.cancelAlert(alert);
    } catch (e) {
      debugPrint('[AlertsNotifier] cancelAlert failed: $e');
    }
    await _repo.save(alert);
    try {
      await _scheduling.scheduleAlert(alert);
    } catch (e) {
      debugPrint('[AlertsNotifier] scheduleAlert(edit) failed: $e');
    }
    state = await AsyncValue.guard(_fetchSorted);
  }

  /// Cancela la notificación de la alerta y la elimina de la base de datos.
  Future<void> delete(String id) async {
    // Buscar en el estado actual para obtener el objeto Alert completo.
    final alerts = state.asData?.value;
    final alert = alerts?.where((a) => a.id == id).firstOrNull;
    if (alert != null) {
      try {
        await _scheduling.cancelAlert(alert);
      } catch (e) {
        debugPrint('[AlertsNotifier] cancelAlert(delete) failed: $e');
      }
    }
    await _repo.delete(id);
    state = await AsyncValue.guard(_fetchSorted);
  }

  /// Invierte [Alert.isActive]: cancela la notificación si se desactiva,
  /// programa si se activa.
  Future<void> toggleActive(Alert alert) async {
    final updated = alert.copyWith(isActive: !alert.isActive);
    // Siempre cancela primero (sea activar o desactivar).
    try {
      await _scheduling.cancelAlert(alert);
    } catch (e) {
      debugPrint('[AlertsNotifier] cancelAlert(toggle) failed: $e');
    }
    await _repo.save(updated);
    if (updated.isActive) {
      try {
        await _scheduling.scheduleAlert(updated);
      } catch (e) {
        debugPrint('[AlertsNotifier] scheduleAlert(toggle) failed: $e');
      }
    }
    state = await AsyncValue.guard(_fetchSorted);
  }
}
