# Arquitectura y trazabilidad técnica — Lulistrack 3.0

## 1. Propósito

Este documento describe la arquitectura que se observa en la implementación de la rama `lulistrack-3.0` y establece una base para mantener alineados el SRS, el RAD, el código y las pruebas. No sustituye los documentos académicos SRS/RAD ni afirma pruebas que todavía no se hayan ejecutado.

## 2. Arquitectura implementada

| Capa / responsabilidad | Tecnología o componente | Responsabilidad observada |
|---|---|---|
| Aplicación móvil | Flutter / Dart | Interfaz del repartidor, navegación, captura de evidencia y operación offline. |
| Autenticación | Supabase Auth | Inicio de sesión, sesión del usuario y solicitud de restablecimiento de contraseña. |
| API de negocio | FastAPI | Consulta y actualización de pedidos, asignaciones, finalización de entregas y ubicación. |
| Persistencia remota | PostgreSQL en Supabase | Datos de pedidos, repartidores, estados, ubicación y metadatos de evidencia. |
| Persistencia local | SQLite mediante sqflite | Caché e información de entregas pendientes para trabajo sin conexión. |
| Evidencia local | OfflineEvidenceStorage | Conservación temporal de fotografías y firmas hasta su sincronización. |
| Notificaciones | Firebase Cloud Messaging | Recepción y registro de notificaciones push. |
| Ubicación | geolocator | Obtención de ubicación del dispositivo bajo permisos del usuario. |
| Biometría | local_auth + almacenamiento seguro | Desbloqueo biométrico opcional; no almacena la contraseña del usuario. |

### 2.1 Flujo de autenticación

1. La aplicación autentica al usuario mediante Supabase Auth.
2. Recupera el token de sesión y lo utiliza para autorizar solicitudes a la API.
3. El backend valida el token y aplica controles de acceso por rol.
4. La biometría funciona como mecanismo local opcional de desbloqueo, no como sustituto de la autenticación del servidor.
5. Desde Seguridad y Privacidad se puede solicitar a Supabase el envío de un enlace de restablecimiento al correo indicado.

### 2.2 Flujo de entrega y comprobante

1. El repartidor consulta y selecciona un pedido.
2. Captura la fotografía de evidencia.
3. El destinatario registra su firma y nombre.
4. La pantalla de revisión permite confirmar la operación.
5. La evidencia se conserva localmente antes de intentar enviarla.
6. La API registra la finalización y los metadatos del comprobante.
7. Si no hay conexión, el registro permanece pendiente y se intenta sincronizar posteriormente.

### 2.3 Operación offline y sincronización

La base SQLite mantiene los registros locales de entregas pendientes. La implementación incluye estados de sincronización, marca temporal de inicio, recuperación de registros estancados, control local de duplicados y conservación de rutas de evidencia. El backend protege la finalización mediante bloqueo de la fila del pedido y comportamiento idempotente para solicitudes repetidas.

La existencia de estas medidas en el código no sustituye las pruebas de modo avión, cierre forzado, pérdida de respuesta HTTP, reintentos y verificación del resultado en PostgreSQL.

### 2.4 Ubicación y notificaciones

La aplicación solicita permisos de ubicación y actualiza la posición del repartidor durante el flujo de pedidos activos configurado en el servicio. Firebase Cloud Messaging gestiona el registro y la recepción de notificaciones. La frecuencia, los permisos, la pausa de seguimiento y el comportamiento con la aplicación en segundo plano deben validarse en dispositivos reales.

## 3. Recomendaciones priorizadas para la iteración

| Recomendación | Área | Evidencia principal en la rama |
|---:|---|---|
| 1 | Arquitectura | Este documento, `lib/services/api_service.dart`, backend FastAPI. |
| 2 | Inicio de sesión y recuperación | `lib/screens/login_screen.dart`, `lib/screens/session_gate_screen.dart`, `lib/screens/security_privacy_screen.dart`. |
| 3 | Pantalla principal | `lib/screens/home_screen.dart`, `lib/screens/main_navigation.dart`. |
| 4 | Asignación de pedidos | `lib/screens/home_screen.dart`, endpoint de claim/assign del backend. |
| 7 | Fotografía | `lib/screens/photo_evidence_screen.dart`. |
| 8 | Firma | `lib/screens/signature_screen.dart`. |
| 9 | Comprobante PoD | `lib/screens/delivery_review_screen.dart`, `lib/screens/delivery_receipt_screen.dart`, finalización de pedido en API. |
| 10 | Funcionamiento offline | `lib/services/offline_database.dart`, `lib/services/offline_evidence_storage.dart`. |
| 11 | Sincronización | `lib/services/offline_sync_service.dart`, finalización idempotente en backend. |
| 12 | Notificaciones | `lib/services/notification_service.dart` y servicio FCM del backend. |
| 15 | GPS | `lib/services/driver_location_service.dart`. |
| 16 | Seguridad y privacidad | `lib/services/biometric_service.dart`, `lib/screens/security_privacy_screen.dart`, autenticación/autorización del backend. |
| 18 | Accesibilidad visual y táctil | `lib/widgets/fitts_touch_target.dart`, `lib/widgets/lulistrack_dialog.dart`, colores de estado de `home_screen.dart`. |
| 19 | Interacción humano-computadora | Flujo de fotografía, firma, revisión y confirmación. |
| 20 | Manejo de errores | `lib/services/offline_sync_service.dart`, pantallas de captura y `lib/widgets/lulistrack_dialog.dart`. |
| 25 | Trazabilidad documental | Esta matriz; requiere cotejo final con los identificadores del SRS y RAD vigentes. |

## 4. Matriz de trazabilidad a completar con los documentos vigentes

Los identificadores RF no se inventan en este archivo. Deben copiarse literalmente desde la versión aprobada del SRS y comprobarse contra el RAD.

| Recomendación | ID RF del SRS | Sección / componente RAD | Archivo o endpoint | Prueba asociada | Estado |
|---:|---|---|---|---|---|
| 1 | Por cotejar | Arquitectura | Este documento / configuración de servicios | Revisión de arquitectura | Documental |
| 2 | Por cotejar | Autenticación | Login, SessionGate, SecurityPrivacy | Inicio, sesión expirada y recuperación | Requiere ejecución |
| 3 | Por cotejar | Interfaz principal | HomeScreen / MainNavigation | Prueba de navegación y consulta | Requiere ejecución |
| 4 | Por cotejar | Asignación | Claim/assign de pedidos | Dos solicitudes concurrentes | Requiere ejecución |
| 7 | Por cotejar | Evidencia fotográfica | PhotoEvidenceScreen | Captura, vista previa y repetición | Requiere ejecución |
| 8 | Por cotejar | Firma | SignatureScreen | Firma vacía, borrar y asociar pedido | Requiere ejecución |
| 9 | Por cotejar | Cierre de entrega | DeliveryReview / API complete | Flujo completo PoD | Requiere ejecución |
| 10 | Por cotejar | Persistencia offline | OfflineDatabase / EvidenceStorage | Modo avión y reinicio | Requiere ejecución |
| 11 | Por cotejar | Sincronización | OfflineSyncService / API complete | Reintentos y duplicados | Requiere ejecución |
| 12 | Por cotejar | Notificaciones | NotificationService / FCM | Primer plano, segundo plano y cerrada | Requiere ejecución |
| 15 | Por cotejar | Ubicación | DriverLocationService | Permisos, pausa y actualización | Requiere ejecución |
| 16 | Por cotejar | Seguridad | Auth, roles, biometría y storage | Autorización y acceso indebido | Requiere auditoría |
| 18 | Por cotejar | Diseño accesible | FittsTouchTarget / colores de estado | Contraste y objetivos táctiles | Requiere ejecución |
| 19 | Por cotejar | Flujo de interacción | Captura, firma y revisión | Prueba de tarea con repartidor | Requiere ejecución |
| 20 | Por cotejar | Manejo de errores | SyncService / diálogos | Desconexión, permisos y reintento | Requiere ejecución |
| 25 | Por cotejar | Trazabilidad | SRS / RAD / UML | Revisión cruzada de identificadores | Documental |

## 5. Criterios de validación antes de declarar terminadas las recomendaciones

- Ejecutar `flutter pub get`, `dart format` y `flutter analyze`.
- Ejecutar pruebas automatizadas disponibles y registrar sus resultados.
- Probar el flujo de entrega con conexión y sin conexión.
- Interrumpir la conexión durante una sincronización y comprobar recuperación.
- Confirmar que una entrega repetida no duplique el comprobante ni el contador del repartidor.
- Probar permisos de cámara, micrófono, notificaciones y ubicación.
- Comprobar la recuperación de contraseña con un proyecto Supabase configurado y una dirección de redirección válida si la aplicación utiliza deep links.
- Revisar la autorización de cada endpoint y las políticas RLS de Supabase.
- Medir contraste de los estados y revisar accesibilidad con herramientas de Android.

## 6. Alcance y limitaciones

Este documento refleja la estructura identificada en el código de la rama `lulistrack-3.0`. No certifica que las pruebas anteriores hayan sido ejecutadas ni que todos los entornos externos (Supabase, Firebase, almacenamiento y permisos del dispositivo) estén configurados correctamente. Los resultados deben registrarse en la matriz de pruebas y en el SRS/RAD correspondiente.
