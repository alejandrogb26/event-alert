import 'models/alert.dart';

/// Contrato de acceso a datos para [Alert].
///
/// La capa de presentación y los servicios dependen de esta interfaz,
/// no de la implementación concreta, lo que facilita el testing y el
/// cambio de mecanismo de persistencia sin tocar el resto de la app.
abstract class AlertRepository {
  /// Inserta o reemplaza una alerta (upsert por id).
  Future<void> save(Alert alert);

  Future<void> delete(String id);

  Future<Alert?> findById(String id);

  Future<List<Alert>> findAll();

  /// Devuelve solo las alertas con [Alert.isActive] == true.
  Future<List<Alert>> findActive();
}
