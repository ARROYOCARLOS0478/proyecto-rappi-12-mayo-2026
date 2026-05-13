# 🟠🔴🟡 PLAN DE IMPLEMENTACIÓN "RAPPI SPIRIT" (PROYECTO DE GRADO)
> **Mentoría:** Enfoque académico, funcional y mantenible. Sin sobre-ingeniería. Buenas prácticas aplicadas a nivel de estudiante avanzado.

---

## 📁 1. Modelado de Carpetas Estándar
Estructura plana y predecible. Ideal para proyectos de grado donde la legibilidad supera a la complejidad arquitectónica.

```text
lib/
├── main.dart                 # Punto de entrada, inicializa Firebase y MultiProvider
├── core/                     # Constantes globales, rutas, utilidades, temas
│   ├── constants.dart        # URLs, strings clave, roles
│   ├── app_theme.dart        # ThemeData corporativo
│   └── app_router.dart       # Definición de rutas (go_router o navigator 2.0)
├── models/                   # Clases de datos (1:1 con colecciones Firestore)
│   ├── user_model.dart
│   ├── merchant_model.dart
│   ├── product_model.dart
│   ├── order_model.dart
│   └── payment_model.dart
├── services/                 # Lógica de infraestructura (Firebase puro)
│   ├── auth_service.dart     # firebase_auth: login, register, logout
│   ├── firestore_service.dart # cloud_firestore: CRUD, streams, consultas
│   └── payment_service.dart  # Lógica de pagos (inicialmente mock/sandbox)
├── providers/                # Gestión de estado (Provider)
│   ├── auth_provider.dart    # Estado de sesión, usuario actual, roles
│   ├── cart_provider.dart    # Items, cantidades, totales, persistencia local
│   ├── order_provider.dart   # Creación, estado en tiempo real, historial
│   └── ui_provider.dart      # Cargadores globales, snackbars, errores
└── ui/                       # Pantallas y componentes visuales
    ├── login/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/ (cards de comercios, buscador, categorías)
    ├── catalog/
    │   ├── merchant_detail.dart
    │   └── product_list.dart
    ├── cart/
    │   └── cart_screen.dart
    ├── checkout/
    │   └── checkout_screen.dart
    ├── tracking/
    │   └── order_tracking.dart
    ├── profile/
    │   └── profile_screen.dart
    └── shared/               # Botones, inputs, loaders, diálogos reutilizables
```

✅ **Nota de Mentor:** Esta estructura evita el `feature-based` complejo que suele confundir en proyectos académicos, manteniendo separación clara: `models` (datos) → `services` (conexión) → `providers` (estado) → `ui` (visualización).

---

## 🗃️ 2. Guía de Base de Datos (Mapeo SQL → Firestore)
Transformación de 5 dominios relacionales a colecciones NoSQL documentales.

| Dominio SQL (Tablas) | Colección Firestore | Estructura del Documento (MVP) | Relación/Clave |
|----------------------|---------------------|--------------------------------|----------------|
| `usuarios` | `users` | `{ uid, email, name, phone, role: 'user'\|'rider', addresses: [{...}], createdAt }` | `uid` = Firebase Auth ID |
| `comercios` | `merchants` | `{ merchantId, name, category, rating, imageUrl, isActive, ownerId }` | `ownerId` = referencia a `users.uid` |
| `productos` | `products` | `{ productId, merchantId, name, description, price, stock, category, imageUrl }` | `merchantId` = referencia a `merchants.merchantId` |
| `pedidos` | `orders` | `{ orderId, userId, merchantId, items: [{productId, name, qty, price}], total, status, address, createdAt, updatedAt }` | `userId` y `merchantId` = referencias |
| `pagos` | `payments` | `{ paymentId, orderId, method, status: 'pending'\|'completed'\|'failed', timestamp, reference }` | `orderId` = referencia a `orders.orderId` |
| `logística` | `deliveries` | `{ deliveryId, orderId, riderId, status: 'assigned'\|'picked_up'\|'in_route'\|'delivered', location, eta }` | `orderId` y `riderId` = referencias |

### 🔗 Estrategia de Relaciones en Firestore
1. **No anides datos que cambien independientemente.** Los productos viven en `products`, el pedido guarda solo `productId`, `name` y `price` al momento de la compra (denormalización controlada).
2. **Usa IDs como referencia, no subcolecciones innecesarias.** `orders` guarda `userId` y `merchantId`. Para obtener historial: `db.collection('orders').where('userId', isEqualTo: uid)`.
3. **Subcolecciones solo para 1:N estricto y aislado.** Ej: `users/{uid}/notifications` si creces, pero para MVP se mantiene todo en colecciones planas.
4. **Reglas de seguridad:** `match /orders/{id} { allow read: if request.auth != null && resource.data.userId == request.auth.uid; }`

---

## 🎨 3. UI/UX & Design System
### 🟠 Paleta Corporativa "Rappi Spirit"
```dart
// core/app_theme.dart (referencia)
static const Color primaryOrange = Color(0xFFFF6C00);
static const Color accentRed   = Color(0xFFE53935);
static const Color highlightYellow = Color(0xFFFFD700);
static const Color bgLight     = Color(0xFFF8F9FA);
static const Color textDark    = Color(0xFF1A1A1A);
static const Color textLight   = Color(0xFFFFFFFF);
```

### ⚙️ Configuración del `ThemeData`
- `primarySwatch`: Naranja personalizado
- `scaffoldBackgroundColor`: `bgLight`
- `appBarTheme`: Fondo blanco, texto oscuro, íconos naranja
- `floatingActionButtonTheme`: `primaryOrange`
- `textTheme`: `Inter` o `Roboto` (sans-serif moderna), pesos `regular/medium/semiBold`
- `elevatedButtonTheme`: Bordes redondeados, sombra suave, texto blanco, fondo naranja
- `inputDecorationTheme`: Bordes sutiles, focusColor naranja, errorColor rojo

### 📱 Pantallas MVP (Producto Mínimo Viable)
1. `SplashScreen` → Verifica sesión activa
2. `LoginScreen` / `RegisterScreen` → Email/Password + validación en tiempo real
3. `HomeScreen` → Grid de comercios, categorías, barra de búsqueda
4. `MerchantDetailScreen` → Menú de productos por categoría
5. `CartScreen` → Resumen, modificación de cantidades, cálculo automático
6. `CheckoutScreen` → Dirección, resumen, confirmación de pedido
7. `OrderTrackingScreen` → Estados: `confirmed → preparing → dispatched → delivered`
8. `ProfileScreen` → Datos básicos, historial de pedidos, cierre de sesión

✅ **Principios UX Académicos:** Estados de carga (`CircularProgressIndicator`), vacíos (`Lottie` o ilustración), errores (`SnackBar`), navegación predecible, retroalimentación táctil (`InkWell`/`GestureDetector`).

---

## 📅 4. Plan de Trabajo Paso a Paso (Cronograma)
| Fase | Duración Estimada | Objetivo | Entregable Clave | Validación |
|------|-------------------|----------|------------------|------------|
| **1. Configuración Firebase** | 3-4 días | Crear proyecto, registrar app, habilitar Auth + Firestore, configurar reglas básicas, inicializar `Firebase.initializeApp()` | `main.dart` funcional, console Firebase conectada | Login con cuenta de prueba, escritura/lectura en consola |
| **2. Login & Registro** | 5-6 días | `AuthService`, `AuthProvider`, pantallas de autenticación, manejo de roles (`user`/`rider`), persistencia de sesión | Flujo completo Auth, redirección a Home tras login | Pruebas de login, registro, error de credenciales, logout |
| **3. Catálogo (Comercios/Productos)** | 6-7 días | `FirestoreService` para lectura, `Provider` de catálogo, UI con grids/listas, búsqueda/filtros básicos | Home poblado con datos reales de Firestore | Carga rápida, scroll fluido, imágenes cacheadas, sin rebuilds innecesarios |
| **4. Lógica del Carrito** | 4-5 días | `CartProvider`, agregar/quitar items, cálculo de totales, validación de stock, persistencia local (`shared_preferences`) | Carrito funcional, actualización en tiempo real, UI responsiva | Pruebas de edge cases: stock 0, vaciado, recálculo exacto |
| **5. Pedido & Seguimiento** | 5-6 días | Creación de `Order` en Firestore, `OrderProvider`, pantalla de tracking con `StreamBuilder`, estados simulados | Checkout exitoso, documento creado, vista de seguimiento | Flujo completo: Carrito → Checkout → Firestore → Tracking en vivo |

📌 **Consejo de Mentor:** No avances a la siguiente fase hasta tener `flutter analyze --fatal-infos` limpio y las pruebas manuales validadas. Usa Firebase Emulator Suite para evitar costos y errores en producción.

---

## 📦 5. Configuración de Dependencias (`pubspec.yaml`)
```yaml
name: rappi_clone
description: Aplicación de pedidos a domicilio - Proyecto de Grado
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: '>=3.16.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # 🔥 Firebase Core & Servicios
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0

  # 📦 Gestión de Estado & Arquitectura
  provider: ^6.1.1

  # 🌐 Utilidades & UI
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  go_router: ^12.1.0
  uuid: ^4.2.1
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
```
> 🔍 **Nota:** Las versiones marcadas son estables a fecha de corte. Ejecuta `flutter pub get` tras crear el proyecto. Si usas Web, asegúrate de habilitar `--web` en la creación y configurar CORS/Firebase Web SDK en la consola.

---

## ✅ Siguientes Pasos
1. Revisa la estructura, el mapeo de datos y el cronograma.
2. Confirma si deseas ajustar algún dominio, añadir notificaciones push (`firebase_messaging`) o geolocalización (`geolocator`) en fases posteriores.
3. **Cuando estés listo, responde con:** `"✅ Aprobar fase 1: Configuración Firebase y Estructura"` y generaré el código exacto para esa fase (archivos, configuración, validaciones), carpeta por carpeta, asegurando que compile y conecte correctamente antes de avanzar.

¿Ajustamos algo o procedemos con la Fase 1? 🟠🚀
