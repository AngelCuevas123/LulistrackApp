# Lulistrack App — 3.0

Aplicación móvil para repartidores de **Lulistrack**, una plataforma de gestión y seguimiento de entregas de última milla. Permite consultar pedidos, aceptar entregas disponibles, registrar comprobantes y continuar trabajando cuando no hay conexión a internet.

Este repositorio contiene la aplicación móvil desarrollada con Flutter.

## Ecosistema Lulistrack

| Componente | Tecnología | Repositorio |
| --- | --- | --- |
| Aplicación móvil | Flutter y Dart | Este repositorio |
| API y lógica de negocio | FastAPI y Python | [BackendLulistrack](https://github.com/AngelCuevas123/BackendLulistrack/tree/lulistrack-3.0) |
| Panel administrativo | React y Vite | [LulistrackDashboard](https://github.com/AngelCuevas123/LulistrackDashboard/tree/lulistrack-3.0) |
| Datos y autenticación | Supabase Auth y PostgreSQL | Proyecto Supabase |
| Notificaciones push | Firebase Messaging e Installation ID | Proyecto Firebase |

## Funcionalidades principales

### Pedidos y entregas
- Inicio de sesión del repartidor mediante Supabase Auth.
- Consulta de pedidos asignados y disponibles.
- Aceptación de pedidos disponibles.
- Consulta del detalle y ubicación de cada pedido.
- Apertura de ubicaciones mediante Google Maps.
- Registro de evidencia de entrega con fotografía y firma del destinatario.
- Consulta del historial de entregas completadas.

### Funcionamiento Offline-First
- Almacenamiento local de pedidos e historial mediante SQLite.
- Conservación local de fotografías y firmas cuando no hay conexión.
- Cola de entregas pendientes de sincronización.
- Reintento de envío al recuperar la conectividad.
- Identificación de entregas que requieren atención cuando el servidor rechaza la evidencia o faltan archivos locales.
- Consulta de información almacenada cuando la API no está disponible.

La sincronización requiere una sesión válida. Si la sesión expira, el repartidor debe volver a iniciar sesión para continuar.

### Notificaciones push
- Integración con Firebase Messaging.
- Registro del Firebase Installation ID (FID) en el backend después del inicio de sesión.
- Asociación del dispositivo con el perfil del repartidor.
- Recepción de notificaciones de asignación de pedidos.
- Desactivación del dispositivo en el backend al cerrar sesión.

## Tecnologías

- **Flutter / Dart:** aplicación móvil.
- **Supabase Flutter:** autenticación y sesión.
- **Firebase Core y Firebase Messaging:** inicialización y notificaciones push.
- **Firebase Installation ID:** identificación de la instalación que recibe notificaciones.
- **SQLite (sqflite):** caché de pedidos e historial y cola local.
- **connectivity_plus:** detección de cambios de conectividad.
- **HTTP:** comunicación con la API REST.
- **image_picker:** captura de fotografías.
- **url_launcher y google_maps_flutter:** apertura y visualización de ubicaciones.

## Arquitectura

~~~text
lib/
├── main.dart
├── firebase_options.dart
├── models/                  # Modelos de pedidos y usuarios
├── screens/                 # Inicio, pedidos, historial y comprobante
├── services/
│   ├── api_service.dart
│   ├── notification_service.dart
│   ├── offline_database.dart
│   ├── offline_evidence_storage.dart
│   └── offline_sync_service.dart
└── widgets/                 # Componentes reutilizables

assets/
└── icon/
    └── lulistrack_icon.png

.env.example
pubspec.yaml
~~~

## Comunicación con la API

La URL base se configura mediante **API_BASE_URL**. En el entorno desplegado se utiliza:

~~~text
https://backendlulistrack.onrender.com
~~~

| Operación | Endpoint |
| --- | --- |
| Pedidos asignados | GET /orders/my |
| Pedidos disponibles | GET /orders/available |
| Aceptar un pedido | POST /orders/{order_id}/claim |
| Completar una entrega | POST /orders/{order_id}/complete |
| Historial del repartidor | GET /orders/my/completed |
| Perfil del repartidor | GET /drivers/me |
| Registrar dispositivo para notificaciones | POST /drivers/me/fcm-token |
| Desactivar dispositivo al cerrar sesión | DELETE /drivers/me/fcm-token |

Las rutas protegidas reciben el token de acceso de Supabase en el encabezado Authorization: Bearer.

## Requisitos

- Flutter SDK y Dart SDK compatibles con pubspec.yaml.
- Android Studio o Visual Studio Code.
- Emulador Android o dispositivo Android físico.
- Acceso al proyecto de Supabase.
- Proyecto Firebase configurado para la aplicación Android.
- Backend de Lulistrack disponible.

## Instalación

Clona la rama 3.0:

~~~bash
git clone --branch lulistrack-3.0 https://github.com/AngelCuevas123/LulistrackApp.git
cd LulistrackApp
flutter pub get
~~~

Crea el archivo local de variables de entorno a partir de la plantilla:

**Windows PowerShell**
~~~powershell
Copy-Item .env.example .env
~~~

**macOS / Linux**
~~~bash
cp .env.example .env
~~~

Configura los valores de tu propio proyecto:

~~~env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_clave_publica
API_BASE_URL=https://backendlulistrack.onrender.com
~~~

La app utiliza la clave pública de Supabase. No agregues claves privadas, contraseñas ni archivos de cuenta de servicio al repositorio.

Ejecuta la aplicación:

~~~bash
flutter run
~~~

## Firebase y notificaciones

La configuración de Firebase para las plataformas se encuentra en lib/firebase_options.dart y en los archivos nativos correspondientes. El backend necesita su propia cuenta de servicio de Firebase Admin SDK, configurada mediante FIREBASE_CREDENTIALS_PATH en el entorno del servidor.

No publiques archivos JSON de cuentas de servicio ni claves privadas. La app registra el FID en el backend al iniciar sesión; el backend utiliza ese identificador para enviar notificaciones al dispositivo activo.

## Pruebas y análisis

Para revisar el código y ejecutar las pruebas disponibles:

~~~bash
flutter analyze
flutter test
~~~

La versión 3.0 fue probada funcionalmente en Android en estos escenarios:
- Inicio de sesión y recepción de notificaciones con la app en segundo plano y con la pantalla bloqueada.
- Consulta de Inicio e Historial sin conexión.
- Registro local de una entrega sin internet y sincronización al recuperar la conexión.

Estas comprobaciones funcionales no sustituyen la ejecución de pruebas automatizadas en cada entorno.

## Compilación Android

~~~bash
flutter build apk --release
~~~

El archivo se genera en:

~~~text
build/app/outputs/flutter-apk/app-release.apk
~~~

Antes de distribuir una versión pública, configura una firma de lanzamiento propia y revisa los requisitos de la tienda de aplicaciones.

## Repositorios

- [Aplicación móvil — rama 3.0](https://github.com/AngelCuevas123/LulistrackApp/tree/lulistrack-3.0)
- [Backend — rama 3.0](https://github.com/AngelCuevas123/BackendLulistrack/tree/lulistrack-3.0)
- [Dashboard — rama 3.0](https://github.com/AngelCuevas123/LulistrackDashboard/tree/lulistrack-3.0)
- [Dashboard desplegado](https://lulistrack-dashboard.vercel.app)
- [API y documentación](https://backendlulistrack.onrender.com/docs)

---

**Lulistrack 3.0** — aplicación móvil para la operación y seguimiento de entregas de última milla.
