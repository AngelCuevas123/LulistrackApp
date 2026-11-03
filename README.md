# Lulistrack App

Aplicacion movil de **Lulistrack**, una plataforma de seguimiento y gestion de entregas de ultima milla. Esta app esta dirigida al repartidor y se conecta con el backend de FastAPI para consultar pedidos, aceptar entregas y registrar comprobantes.

## Descripcion general

Lulistrack ayuda al repartidor a consultar sus pedidos, revisar la informacion de cada entrega, abrir la ubicacion en Google Maps y registrar la entrega mediante evidencia fotografica y firma del destinatario.

La aplicacion forma parte del ecosistema Lulistrack:

| Componente | Tecnologia | Ubicacion |
|---|---|---|
| App movil | Flutter y Dart | Este repositorio |
| API | FastAPI y Python | [BackendLulistrack](https://github.com/AngelCuevas123/BackendLulistrack) |
| Dashboard web | React y Vite | [LulistrackDashboard](https://github.com/AngelCuevas123/LulistrackDashboard) |
| Base de datos y autenticacion | Supabase y PostgreSQL | Proyecto Supabase |

## Funcionalidades

### Cuenta y acceso
- Inicio de sesion con correo y contrasena mediante Supabase Auth.
- Envio del token de sesion en las solicitudes protegidas al backend.

### Pedidos y rutas
- Consulta de pedidos asignados al repartidor.
- Consulta de pedidos disponibles.
- Aceptacion de pedidos disponibles.
- Busqueda de pedidos por cliente, numero de seguimiento o direccion.
- Consulta del detalle de cada pedido.
- Apertura de la ubicacion del pedido en Google Maps mediante un enlace externo.
- Actualizacion de las listas mediante gesto de recarga.

### Comprobante de entrega
- Captura de fotografia con la camara del dispositivo.
- Captura de firma del destinatario en pantalla.
- Vista previa y confirmacion del comprobante.
- Envio de fotografia y firma codificadas en Base64 al backend.
- Pantalla de recibo al completar el envio.

### Historial y perfil
- Consulta del historial de entregas completadas.
- Pantallas de perfil, datos personales, notificaciones, seguridad y ayuda.
- Secciones de manual del repartidor, soporte tecnico y reporte de problemas.

> Algunas pantallas de perfil, configuracion y soporte contienen actualmente contenido de muestra o elementos de interfaz. Consulta la seccion de pendientes antes de considerar esas funciones terminadas.

## Tecnologias

- **Flutter / Dart:** desarrollo de la aplicacion movil.
- **Supabase Flutter:** autenticacion y manejo de sesiones.
- **HTTP:** comunicacion con la API REST.
- **FastAPI:** backend que administra pedidos y repartidores.
- **PostgreSQL en Supabase:** persistencia de datos del sistema.
- **image_picker:** captura de fotografia.
- **url_launcher:** apertura de ubicaciones en Google Maps.
- **intl:** utilidades de formato.
- **flutter_launcher_icons:** generacion de iconos de la aplicacion.

## Arquitectura del proyecto

La aplicacion utiliza una organizacion sencilla por responsabilidades: modelos para representar datos, servicios para comunicarse con el backend, pantallas para la interfaz y widgets reutilizables.

```text
lulistrack_app/
├── android/                         # Configuracion nativa Android
├── ios/                             # Configuracion nativa iOS
├── linux/                           # Configuracion Linux generada por Flutter
├── macos/                           # Configuracion macOS generada por Flutter
├── web/                             # Configuracion web generada por Flutter
├── windows/                         # Configuracion Windows generada por Flutter
├── assets/
│   └── icon/
│       └── lulistrack_icon.png      # Icono de la aplicacion
├── lib/
│   ├── main.dart                    # Inicializacion de Supabase y aplicacion
│   ├── models/
│   │   ├── order_model.dart         # Modelo de pedidos
│   │   └── user_model.dart          # Modelo de repartidor
│   ├── screens/
│   │   ├── login_screen.dart        # Inicio de sesion
│   │   ├── main_navigation.dart     # Navegacion principal
│   │   ├── home_screen.dart         # Inicio y pedidos
│   │   ├── my_route_screen.dart     # Pedidos asignados / entregas
│   │   ├── route_list_screen.dart   # Lista y apertura de ubicaciones
│   │   ├── order_detail_screen.dart # Detalle del pedido
│   │   ├── history_screen.dart      # Historial completado
│   │   ├── home_delivered_screen.dart
│   │   ├── photo_evidence_screen.dart
│   │   ├── signature_screen.dart
│   │   ├── delivery_review_screen.dart
│   │   ├── delivery_receipt_screen.dart
│   │   ├── proof_of_delivery_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── personal_data_screen.dart
│   │   ├── notifications_settings_screen.dart
│   │   ├── security_privacy_screen.dart
│   │   ├── help_support_screen.dart
│   │   ├── tech_support_screen.dart
│   │   ├── bug_report_screen.dart
│   │   └── driver_manual_screen.dart
│   ├── services/
│   │   └── api_service.dart         # Solicitudes HTTP al backend
│   └── widgets/
│       ├── custom_button.dart       # Boton reutilizable
│       └── order_card.dart          # Tarjeta de pedido
├── test/
│   └── widget_test.dart             # Prueba basica de interfaz
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Servicios y comunicacion con el backend

La clase `ApiService` centraliza las solicitudes principales. La URL base configurada actualmente es:

```text
https://backendlulistrack.onrender.com
```

| Operacion en la app | Endpoint |
|---|---|
| Pedidos asignados al repartidor | `GET /orders/my` |
| Pedidos disponibles | `GET /orders/available` |
| Aceptar un pedido | `POST /orders/{order_id}/claim` |
| Completar entrega con evidencia | `POST /orders/{order_id}/complete` |
| Consultar perfil del repartidor | `GET /drivers/{driver_id}` |
| Historial de entregas | `GET /orders/my/completed` |

Las rutas protegidas reciben el token de Supabase en el encabezado:

```http
Authorization: Bearer <access_token>
```

El comprobante de entrega envia la fotografia y la firma como cadenas Base64, junto con la fecha y hora del registro.

La pantalla de historial realiza actualmente su solicitud HTTP directamente, en lugar de utilizar `ApiService`.

## Requisitos

- Flutter SDK compatible con el SDK declarado en `pubspec.yaml`.
- Dart SDK compatible con el proyecto.
- Android Studio o Visual Studio Code.
- Un emulador Android o dispositivo fisico.
- Acceso al proyecto Supabase y al backend de Lulistrack.

## Instalacion y ejecucion

Clona el repositorio:

```bash
git clone https://github.com/AngelCuevas123/LulistrackApp.git
cd LulistrackApp
```

Instala las dependencias:

```bash
flutter pub get
```

Verifica la instalacion:

```bash
flutter doctor
```

Ejecuta la aplicacion:

```bash
flutter run
```

## Configuracion

### Supabase

La inicializacion de Supabase se encuentra actualmente en `lib/main.dart`, donde se configura la URL del proyecto y una clave publica de cliente (publishable key).

Para usar otro proyecto, actualiza esos valores en la configuracion de la app. No agregues una clave `service_role`, contrasenas de base de datos ni secretos administrativos a una aplicacion movil: el contenido compilado puede ser inspeccionado.

La clave publica no sustituye las politicas de seguridad. Las tablas y recursos deben estar protegidos con las politicas de acceso correspondientes y el backend debe validar cada token.

### Backend

La URL de la API se configura en `lib/services/api_service.dart`. Si se cambia el entorno del backend, actualiza esa direccion y verifica que los endpoints y permisos sigan coincidiendo.

### Permisos Android

El manifiesto de Android declara permisos de internet, camara y ubicacion. El sistema solicita los permisos correspondientes cuando una funcion del dispositivo los necesita.

## Pruebas y analisis

Ejecuta el analizador estatico:

```bash
flutter analyze
```

Ejecuta las pruebas:

```bash
flutter test
```

## Compilacion

Generar APK de Android:

```bash
flutter build apk --release
```

Generar Android App Bundle:

```bash
flutter build appbundle --release
```

Los archivos se generan en:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

Para distribuir la app en produccion, configura una firma de lanzamiento propia. La configuracion actual de Gradle utiliza la firma de depuracion para el tipo `release`, por lo que no debe considerarse lista para publicar en Google Play.

## Pendientes tecnicos identificados

Estos puntos se documentan para dar continuidad al desarrollo; no se modifico la logica de la app en esta actualizacion documental.

1. **Sesion de Supabase:** el token se guarda actualmente en una variable estatica de `ApiService` al iniciar sesion. Conviene obtener la sesion vigente desde Supabase y contemplar la renovacion del token.
2. **Persistencia del acceso:** la app inicia directamente en la pantalla de login. Falta comprobar la sesion guardada al abrir de nuevo la aplicacion.
3. **Cerrar sesion:** el boton de perfil navega al login, pero debe ejecutar tambien `Supabase.instance.client.auth.signOut()` y limpiar el estado de autenticacion.
4. **Datos de muestra:** el perfil, el nombre del destinatario y algunos datos del recibo muestran valores fijos. Deben sustituirse por datos reales del usuario y del pedido.
5. **Acceso rapido a la camara:** el boton flotante de navegacion abre el comprobante con un identificador de pedido de ejemplo. Lo ideal es iniciar el flujo desde un pedido seleccionado.
6. **Entregas completadas:** `home_delivered_screen.dart` consulta actualmente `getActiveOrders()`. Hay que confirmar si debe utilizar el endpoint de pedidos completados.
7. **Mapas:** la lista abre Google Maps mediante `url_launcher`. Aunque `google_maps_flutter` esta declarado como dependencia, no se encontro un mapa integrado en las pantallas revisadas.
8. **Firma de Android:** cambiar la firma de depuracion por una configuracion de firma de lanzamiento antes de distribuir la aplicacion.
9. **Pruebas:** ampliar las pruebas para cubrir inicio de sesion, carga de pedidos, aceptacion y envio del comprobante.

## Repositorios relacionados

- [BackendLulistrack](https://github.com/AngelCuevas123/BackendLulistrack)
- [LulistrackDashboard](https://github.com/AngelCuevas123/LulistrackDashboard)
- [LulistrackApp](https://github.com/AngelCuevas123/LulistrackApp)

---

**Lulistrack** — seguimiento y gestion de entregas de ultima milla.
