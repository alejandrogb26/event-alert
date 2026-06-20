import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionStatus { granted, denied, permanentlyDenied }

/// Gestiona permisos de la app mediante [permission_handler].
///
/// Singleton. No muestra diálogos propios ni abre Settings automáticamente;
/// la responsabilidad de la UI queda en la capa de presentación.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Comprueba el estado actual sin solicitar el permiso.
  Future<NotificationPermissionStatus> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return _map(status);
  }

  /// Solicita POST_NOTIFICATIONS (Android 13+ / API 33+).
  ///
  /// En Android < 13, el permiso se concede automáticamente.
  /// Si el usuario ya lo denegó permanentemente, devuelve [permanentlyDenied]
  /// sin mostrar el diálogo de nuevo; la app debe seguir funcionando sin
  /// programar notificaciones.
  Future<NotificationPermissionStatus> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return _map(status);
  }

  NotificationPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted) return NotificationPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    return NotificationPermissionStatus.denied;
  }
}
