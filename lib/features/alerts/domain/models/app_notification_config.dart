const _absent = Object();

/// Configuración de notificación local asociada a una alerta o evento.
///
/// Separada de las clases de paquetes externos para no acoplar el dominio
/// a la API de flutter_local_notifications.
class AppNotificationConfig {
  const AppNotificationConfig({
    this.enabled = true,
    this.minutesBefore = 0,
    this.customSound,
    this.vibration = true,
  });

  /// Si la notificación está habilitada.
  final bool enabled;

  /// Minutos de antelación respecto al trigger. 0 = en el momento exacto.
  final int minutesBefore;

  /// Ruta del asset de sonido personalizado. null = sonido del sistema.
  final String? customSound;

  /// Si la notificación debe vibrar.
  final bool vibration;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'minutesBefore': minutesBefore,
        if (customSound != null) 'customSound': customSound,
        'vibration': vibration,
      };

  factory AppNotificationConfig.fromJson(Map<String, dynamic> json) =>
      AppNotificationConfig(
        enabled: json['enabled'] as bool? ?? true,
        minutesBefore: json['minutesBefore'] as int? ?? 0,
        customSound: json['customSound'] as String?,
        vibration: json['vibration'] as bool? ?? true,
      );

  AppNotificationConfig copyWith({
    bool? enabled,
    int? minutesBefore,
    Object? customSound = _absent,
    bool? vibration,
  }) =>
      AppNotificationConfig(
        enabled: enabled ?? this.enabled,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        customSound: identical(customSound, _absent)
            ? this.customSound
            : customSound as String?,
        vibration: vibration ?? this.vibration,
      );

  @override
  String toString() =>
      'AppNotificationConfig(enabled: $enabled, minutesBefore: $minutesBefore, '
      'customSound: $customSound, vibration: $vibration)';
}
