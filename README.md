# Lulistrack App

Aplicacion movil de **Lulistrack**, una plataforma de seguimiento y gestion de entregas de ultima milla. Esta app esta dirigida al repartidor y se conecta con el backend de FastAPI para consultar pedidos, aceptar entregas y registrar comprobantes.

## Descripcion general

Lulistrack ayuda al repartidor a consultar sus pedidos, revisar la informacion de cada entrega, abrir la ubicacion en Google Maps y registrar la entrega mediante evidencia fotografica y firma del destinatario.

La aplicacion forma parte del ecosistema Lulistrack:

## Como se autoriza el acceso a la app

En Lulistrack no existe un registro publico desde la aplicacion movil. El acceso de cada repartidor se habilita desde el Dashboard por una cuenta con permisos de administrador.

1. El administrador inicia sesion en el [Dashboard de Lulistrack](https://lulistrack-dashboard.vercel.app).
2. Entra a la seccion **Repartidores** y selecciona **Nuevo repartidor**.
3. Captura el nombre, correo electronico, contraseña inicial y vehiculo.
4. Al confirmar, el backend verifica que la solicitud venga de un administrador autorizado. Despues crea la cuenta en **Supabase Auth**, confirma el correo y registra el perfil del repartidor en PostgreSQL.
5. El repartidor abre esta app e inicia sesion con el mismo correo y contraseña que el administrador registro.

Este proceso vincula la cuenta de autenticacion con el perfil de repartidor. Por eso, crear el usuario desde el Dashboard es el paso necesario para que pueda entrar a Flutter. No se debe crear la cuenta directamente desde la pantalla movil ni compartir credenciales administrativas.

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
├── .env.example                    # Plantilla de configuracion (sin claves reales)
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

## Configuracion con .env

La app lee su configuracion desde un archivo `.env` ubicado en la raiz del proyecto. Este archivo se carga al iniciar Flutter y contiene las direcciones de los servicios y la clave publica de Supabase.

1. Copia el archivo de ejemplo:
   ```bash
   copy .env.example .env
   ```
   En macOS o Linux puedes usar `cp .env.example .env`.
2. Abre `.env` y coloca los valores de tu proyecto:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu_clave_publica_anon_o_publishable
   API_BASE_URL=https://tu-backend.onrender.com
   ```
3. Instala las dependencias y ejecuta la app:
   ```bash
   flutter pub get
   flutter run
   ```

El archivo `.env.example` se incluye en GitHub como guia, pero el archivo `.env` real esta excluido por `.gitignore`. Si clonas el proyecto en otro equipo, debes crear tu propio `.env` antes de ejecutar o compilar la app.

**Importante:** los valores de Supabase que utiliza el cliente movil son la URL y la clave publica anon/publishable. Aunque el archivo `.env` no se sube al repositorio, Flutter incorpora los assets al paquete de la aplicacion; por eso estos valores no deben considerarse secretos. Nunca coloques en este archivo una clave `service_role`, contraseñas de base de datos, tokens privados ni credenciales administrativas. La seguridad depende tambien de las politicas RLS y de la validacion de permisos en el backend.

### Backend

La URL de la API se define mediante `API_BASE_URL` en `.env`. Si cambio de entorno, actualizo ese valor sin modificar el codigo fuente.

### Permisos Android

El manifiesto de Android declara permisos de internet, camara y ubicacion. El sistema solicita los permisos correspondientes cuando una funcion del dispositivo los necesita.

## Pruebas y analisis

He probado la aplicacion en dispositivos Android e iOS y confirme su funcionamiento durante el uso del proyecto. Para repetir las verificaciones tecnicas desde otro equipo, ejecuto:

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

## Estado de validacion

He ejecutado y probado la aplicacion en Android y iOS durante el desarrollo. La configuracion de lanzamiento para distribucion publica (por ejemplo, firma propia para Google Play o App Store) se debe preparar de acuerdo con los requisitos de cada tienda.
## Repositorios relacionados

- [BackendLulistrack](https://github.com/AngelCuevas123/BackendLulistrack)
- [LulistrackDashboard](https://github.com/AngelCuevas123/LulistrackDashboard)
- [LulistrackApp](https://github.com/AngelCuevas123/LulistrackApp)

---

**Lulistrack** — seguimiento y gestion de entregas de ultima milla.
