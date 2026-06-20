import '../domain/alert_repository.dart';
import '../domain/models/alert.dart';
import 'alert_dao.dart';

/// Implementación de [AlertRepository] que delega en [AlertDao].
///
/// Toda la lógica de acceso a SQLite vive en el DAO. El repositorio actúa
/// como punto de entrada limpio para la capa de presentación y los servicios.
class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl(this._dao);

  final AlertDao _dao;

  @override
  Future<void> save(Alert alert) => _dao.insert(alert);

  @override
  Future<void> delete(String id) => _dao.delete(id);

  @override
  Future<Alert?> findById(String id) => _dao.findById(id);

  @override
  Future<List<Alert>> findAll() => _dao.findAll();

  @override
  Future<List<Alert>> findActive() => _dao.findActive();
}
