const _absent = Object();

/// Configuración de alarma sonora asociada a una alerta o evento.
///
/// Separada de las clases del paquete alarm para no acoplar el dominio
/// a la API externa.
class AppAlarmConfig {
  const AppAlarmConfig({
    this.enabled = false,
    this.fullScreen = false,
    this.soundAsset,
    this.looping = true,
    this.snoozeMinutes = 5,
  });

  /// Si la alarma sonora está habilitada.
  final bool enabled;

  /// Si la alarma debe mostrarse en pantalla completa al dispararse.
  final bool fullScreen;

  /// Ruta del asset de audio. null = sonido de alarma por defecto del paquete.
  final String? soundAsset;

  /// Si el audio debe reproducirse en bucle hasta que el usuario la detenga.
  final bool looping;

  /// Minutos de posponer. 0 = sin opción de posponer.
  final int snoozeMinutes;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'fullScreen': fullScreen,
    if (soundAsset != null) 'soundAsset': soundAsset,
    'looping': looping,
    'snoozeMinutes': snoozeMinutes,
  };

  factory AppAlarmConfig.fromJson(Map<String, dynamic> json) => AppAlarmConfig(
    enabled: json['enabled'] as bool? ?? false,
    fullScreen: json['fullScreen'] as bool? ?? false,
    soundAsset: json['soundAsset'] as String?,
    looping: json['looping'] as bool? ?? true,
    snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
  );

  AppAlarmConfig copyWith({
    bool? enabled,
    bool? fullScreen,
    Object? soundAsset = _absent,
    bool? looping,
    int? snoozeMinutes,
  }) => AppAlarmConfig(
    enabled: enabled ?? this.enabled,
    fullScreen: fullScreen ?? this.fullScreen,
    soundAsset: identical(soundAsset, _absent)
        ? this.soundAsset
        : soundAsset as String?,
    looping: looping ?? this.looping,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
  );

  @override
  String toString() =>
      'AppAlarmConfig(enabled: $enabled, fullScreen: $fullScreen, '
      'soundAsset: $soundAsset, looping: $looping, snoozeMinutes: $snoozeMinutes)';
}
