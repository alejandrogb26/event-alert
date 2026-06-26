# Event Alert

Event Alert es una aplicación Flutter para gestionar alertas recurrentes y eventos puntuales con notificaciones locales y alarmas sonoras. Está pensada principalmente para Android y combina persistencia local en SQLite, estado con Riverpod, calendario visual y alarmas usando una copia local versionada del paquete `alarm`.

La app está en fase de beta funcional: permite crear, editar, eliminar, activar y programar alertas/eventos, reproduce alarmas sonoras, muestra notificaciones del sistema y abre una pantalla Flutter de alarma cuando la aplicación está activa o se abre desde el flujo disponible del plugin.

## Características Principales

- Alertas recurrentes diarias, semanales y mensuales.
- Eventos puntuales con calendario y duración opcional.
- Notificaciones locales programadas.
- Alarmas sonoras con foreground service en Android.
- Pantalla Flutter de alarma activa con acciones `Detener` y `Posponer`.
- Reprogramación de alertas recurrentes tras detener desde la pantalla Flutter.
- Persistencia local con SQLite.
- Interfaz en español con Material 3.
- Arquitectura por features y servicios desacoplados.

## Estado Actual

Funciona actualmente:

- CRUD de alertas y eventos.
- Cálculo de próxima ocurrencia de alertas recurrentes.
- Programación y cancelación de notificaciones.
- Programación y cancelación de alarmas sonoras.
- Snooze desde la pantalla Flutter de alarma.
- Detección de capacidad de alarmas exactas en Android.
- Pruebas unitarias de recurrencias, serialización, IDs estables y ciclo de vida de alarmas.

No implementado actualmente:

- Pantalla fullscreen nativa de Android.
- Snooze desde la notificación nativa del plugin.
- Garantía de reprogramación si el usuario detiene la alarma exclusivamente desde el botón nativo de la notificación del plugin.

La integración funcional de full-screen intent está retirada. Las alarmas se programan explícitamente con `androidFullScreenIntent: false`.

## Arquitectura

La estructura principal del proyecto es:

```text
lib/
  app.dart
  main.dart
  core/
  features/
    alarm/
    alerts/
    events/
  navigation/
  services/
    alarm/
    database/
    notifications/
    permissions/
    scheduling/
android/
third_party/alarm/
test/
```

Flujo general de datos:

```text
UI -> Provider -> Repository -> DAO -> SQLite
```

Flujo de alarmas:

```text
Formulario
-> AlertsNotifier / EventsNotifier
-> SchedulingService
-> AlarmService
-> package:alarm
-> Android AlarmReceiver
-> AlarmService foreground service del plugin
-> audio + notificación del plugin
-> Alarm.ringing
-> EventAlertApp
-> AlarmRingingScreen
-> AlarmLifecycleService
```

### Capas Principales

- `features/alerts`: dominio, persistencia, providers y UI de alertas recurrentes.
- `features/events`: dominio, persistencia, providers y calendario de eventos.
- `features/alarm`: pantalla Flutter mostrada cuando una alarma está activa.
- `services/database`: apertura y creación de la base SQLite.
- `services/notifications`: wrapper de `flutter_local_notifications`.
- `services/alarm`: integración encapsulada con `package:alarm` y lifecycle de stop/snooze.
- `services/scheduling`: orquesta notificaciones y alarmas para alertas y eventos.
- `services/permissions`: permisos Android relevantes, especialmente alarmas exactas.

## Funcionalidades

### Alertas Recurrentes

Las alertas permiten configurar una hora y una regla de repetición. Tipos soportados:

- Diaria.
- Semanal, con selección de días.
- Mensual por día del mes.
- Mensual el primer día del mes.

Cada alerta puede tener:

- Título y descripción.
- Notificación local opcional.
- Alarma sonora opcional.
- Minutos de snooze.
- Fecha límite opcional.
- Estado activo/inactivo.

Al detener una alerta desde `AlarmRingingScreen`, se actualiza `lastTriggeredAt` y se programa la siguiente ocurrencia si existe.

### Eventos Puntuales

Los eventos se gestionan desde una vista de calendario y pueden incluir:

- Título y descripción.
- Fecha y hora.
- Duración opcional.
- Notificación local.
- Alarma sonora.
- Snooze.

Al editar o eliminar un evento, se cancelan las notificaciones y alarmas asociadas antes de reprogramar o borrar.

### Alarmas Sonoras

Las alarmas usan el paquete local `alarm`, encapsulado por `AlarmService`. El resto de la aplicación no importa directamente `package:alarm/alarm.dart`.

El comportamiento actual es:

- Se programa una alarma futura con `Alarm.set(...)`.
- Android dispara el receiver del plugin.
- El plugin inicia un foreground service.
- Se reproduce audio usando el stream de alarma.
- Se muestra la notificación del plugin.
- Si Flutter recibe `Alarm.ringing`, se abre `AlarmRingingScreen`.
- La pantalla Flutter ofrece `Detener` y, si aplica, `Posponer`.

No hay fullscreen nativo. En pantalla bloqueada o con la app cerrada, la experiencia principal es sonido + notificación del plugin.

## Persistencia

La base de datos local se crea con `sqflite` en `event_alert.db`.

Tablas:

```text
alerts
calendar_events
```

Campos principales de `alerts`:

- `id`
- `title`
- `description`
- `time_minutes`
- `recurrence`
- `notification_config`
- `alarm_config`
- `is_active`
- `created_at`
- `last_triggered_at`

Campos principales de `calendar_events`:

- `id`
- `title`
- `description`
- `start_datetime`
- `duration_ms`
- `notification_config`
- `alarm_config`
- `created_at`

Las fechas se guardan como epoch milliseconds. Los campos persistidos que representan instantes se restauran como UTC cuando corresponde. La UI convierte a hora local para mostrar y programar.

Las configuraciones complejas se guardan como JSON:

- `recurrence`
- `notification_config`
- `alarm_config`

`AppAlarmConfig.fullScreen` permanece en el modelo y en el JSON por compatibilidad con datos existentes, pero actualmente no tiene efecto funcional ni visual.

## Android

Configuración principal:

```text
compileSdk = 36
minSdk = 24
targetSdk = 35
applicationId = local.alejandrogb.event_alert
```

Permisos declarados directamente por la app:

- `POST_NOTIFICATIONS`
- `VIBRATE`
- `RECEIVE_BOOT_COMPLETED`

El plugin local `alarm` aporta permisos y componentes propios para receiver, boot receiver, wake lock, foreground service, exact alarms y reproducción en servicio foreground.

`MainActivity.kt` expone un MethodChannel para consultar `canScheduleExactAlarms` en Android 12+.

## Dependencias Relevantes

- `flutter_riverpod`: estado de aplicación y notifiers.
- `sqflite`: persistencia SQLite.
- `table_calendar`: calendario de eventos.
- `flutter_local_notifications`: notificaciones locales.
- `timezone`: programación con zona horaria.
- `flutter_timezone`: detección de zona horaria local.
- `permission_handler`: permisos de notificaciones.
- `intl`: localización y formato de fechas.
- `uuid`: generación de IDs.
- `alarm`: alarmas sonoras Android/iOS, usado desde `third_party/alarm`.

### Paquete Local `alarm`

El proyecto usa una copia local versionada:

```yaml
alarm:
  path: third_party/alarm
```

Versión vendorizada:

```text
alarm 5.5.0
```

Parche local aplicado:

```text
third_party/alarm/android/build.gradle
compileSdkVersion 34 -> 36
```

`third_party/**` está excluido del analyzer en `analysis_options.yaml`.

## Requisitos de Desarrollo

- Flutter compatible con Dart `^3.12.2`.
- Android SDK con `compileSdk 36` instalado.
- JDK 17 para Android build.
- Dispositivo o emulador Android para probar alarmas reales.

## Instalación y Ejecución

Instalar dependencias:

```bash
flutter pub get
```

Ejecutar en dispositivo conectado:

```bash
flutter run
```

Construir APK debug:

```bash
flutter build apk --debug
```

Instalar APK debug manualmente:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Verificación

Comandos habituales:

```bash
flutter analyze
flutter test
git diff --check
flutter build apk --debug
```

Para evitar resolver paquetes durante una comprobación rápida:

```bash
flutter analyze --no-pub
```

La suite actual incluye pruebas de:

- Recurrencias.
- Texto de recurrencias.
- IDs estables.
- Serialización de alertas.
- Serialización de eventos.
- Restauración UTC desde SQLite.
- Parseo de payloads de alarma.
- Snooze efectivo.
- Próxima ocurrencia tras detener una alerta.

## Pruebas Manuales Recomendadas

Antes de distribuir o crear una build de prueba amplia, validar en un dispositivo Android real:

1. Crear alerta para dentro de 2 minutos con alarma sonora.
2. Confirmar `Alarm.set(...)`, sonido, notificación y `Alarm.ringing`.
3. Pulsar `Detener` desde la pantalla Flutter.
4. Confirmar que una alerta recurrente se reprograma.
5. Repetir usando `Posponer`.
6. Probar evento puntual con notificación y alarma.
7. Probar con teléfono bloqueado.
8. Probar con app en background.
9. Probar tras reinicio real del teléfono.

## Limitaciones Conocidas

- No existe pantalla fullscreen nativa de alarma.
- La pantalla Flutter depende de que Flutter reciba `Alarm.ringing`.
- En app cerrada o teléfono bloqueado, el comportamiento principal es sonido + notificación del plugin.
- El botón nativo `Detener` del plugin puede detener el audio sin pasar por `AlarmLifecycleService`; esto puede afectar la reprogramación de alertas recurrentes.
- No hay snooze desde la notificación nativa.
- La política final de `USE_EXACT_ALARM` y `SCHEDULE_EXACT_ALARM` debe revisarse antes de distribución pública.
- Flutter muestra warnings de futuro sobre plugins que aplican Kotlin Gradle Plugin: `alarm` y `flutter_timezone`.

## Estado Git y Versionado

Debe versionarse:

- `lib/`
- `android/`
- `test/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `third_party/alarm/`

No debe versionarse:

- `build/`
- `.dart_tool/`
- `.flutter-plugins-dependencies`
- APKs generados.
- Cachés locales.

## Roadmap Técnico

Prioridad alta:

- Validar comportamiento tras reinicio real.
- Decidir qué logs de diagnóstico se mantienen antes de distribución.
- Resolver reprogramación cuando se usa el botón nativo `Detener` del plugin.
- Revisar política final de alarmas exactas.

Fiabilidad:

- Añadir tests de integración para `SchedulingService`.
- Probar escenarios de cambio de zona horaria y DST.
- Verificar comportamiento en varios fabricantes Android.

Funcionalidad futura:

- Snooze desde notificación nativa.
- Diagnóstico visible de permisos.
- Historial de disparos.
- Ajustes globales de alarma.

UX/UI:

- Mejor feedback cuando una alarma no puede programarse por fecha pasada.
- Pantalla de permisos y estado del sistema.
- Mejor onboarding para explicar sonido, notificación y limitaciones sin fullscreen nativo.
