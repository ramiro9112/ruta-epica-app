# Ruta Épica — App Oficial

App móvil Android para la agencia de viajes premium **Ruta Épica**.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Dart) |
| Estado | Riverpod (flutter_riverpod 2.x) |
| Navegación | go_router 13.x |
| Backend | Supabase (Auth + PostgreSQL + Storage) |
| UI | Material 3, Google Fonts (Montserrat) |
| Imágenes | cached_network_image |
| Animaciones | flutter_animate |
| Carrusel | carousel_slider + smooth_page_indicator |
| HTTP/WhatsApp | url_launcher |

---

## Prerequisitos

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio o VS Code con extensión Flutter
- Cuenta en [Supabase](https://supabase.com)

---

## Configuración de Supabase

1. Crear un proyecto en [app.supabase.com](https://app.supabase.com)
2. Ir a **SQL Editor** y ejecutar el contenido de `supabase/schema.sql`
3. Copiar la **Project URL** y la **anon key** desde Project Settings > API

---

## Instalación

```bash
# Clonar el repositorio
git clone <repo-url>
cd ruta_epica

# Instalar dependencias
flutter pub get

# Configurar Supabase (editar lib/main.dart)
# Reemplazar 'YOUR_SUPABASE_URL' y 'YOUR_SUPABASE_ANON_KEY'
```

---

## Ejecutar

```bash
# Modo debug
flutter run

# Build APK release
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

---

## Estructura del proyecto

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp.router
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      # Paleta de colores Ruta Épica
│   │   ├── app_strings.dart     # Textos UI en español
│   │   └── app_assets.dart      # Rutas de assets
│   ├── router/
│   │   └── app_router.dart      # go_router config
│   ├── theme/
│   │   └── app_theme.dart       # ThemeData completo
│   └── utils/
│       └── extensions.dart      # String, DateTime, num extensions
├── data/
│   ├── models/                  # DestinationModel, BookingModel, etc.
│   ├── repositories/            # Acceso a Supabase
│   └── services/
│       └── supabase_service.dart # Singleton Supabase wrapper
└── presentation/
    ├── providers/               # Riverpod providers
    ├── screens/
    │   ├── splash/
    │   ├── onboarding/
    │   ├── auth/                # Login, Register, ForgotPassword
    │   ├── home/                # HomeScreen (BottomNav) + ExploreScreen
    │   ├── destinations/        # List + Detail
    │   ├── search/
    │   ├── favorites/
    │   ├── bookings/            # Form + List + Confirmation
    │   └── profile/
    └── widgets/                 # Componentes reutilizables
```

---

## Colores de marca

| Token | Color | Uso |
|---|---|---|
| deepBlue | #0B2F5C | Primary, AppBar |
| gold | #D4A017 | Accent, botones CTA |
| turquoise | #00BFA5 | Tertiary, badges |
| white | #FFFFFF | Fondos de card |
| lightGray | #F5F7FA | Background |
| darkText | #1A1A2E | Texto principal |

---

## Rutas

| Path | Pantalla |
|---|---|
| /splash | SplashScreen |
| /onboarding | OnboardingScreen (3 slides) |
| /login | LoginScreen |
| /register | RegisterScreen |
| /forgot-password | ForgotPasswordScreen |
| /home/explore | ExploreScreen (Inicio) |
| /home/search | SearchScreen |
| /home/favorites | FavoritesScreen |
| /home/bookings | BookingsListScreen |
| /home/profile | ProfileScreen |
| /destination/:id | DestinationDetailScreen |
| /destinations | DestinationsListScreen |
| /booking/:destinationId | BookingFormScreen |
| /booking/confirmation | BookingConfirmationScreen |

---

## Funcionalidades

- Onboarding de 3 pantallas con animaciones
- Autenticación completa con Supabase (login, registro, reset password)
- Catálogo de destinos con filtros por categoría
- Búsqueda de paquetes en tiempo real
- Sistema de favoritos persistente
- Formulario de reservas en 3 pasos
- Historial de reservas del usuario
- Perfil editable con foto de avatar
- Carrusel de promociones destacadas
- WhatsApp FAB para contacto directo
- Soporte offline para datos cacheados
- Tabs "Próximamente" para vuelos, hoteles, autos y actividades

---

## Licencia

MIT — Ruta Épica 2024
