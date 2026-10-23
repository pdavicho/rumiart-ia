# RumiArt IA 🎨

> App móvil de reconocimiento inteligente de obras de arte para el **Museo y Centro Cultural Rumiñahui**, Ecuador.

---

## 📱 Características

| Funcionalidad | Descripción |
|---|---|
| 🔍 **Reconocimiento visual** | Identifica 19 obras de arte con modelos TFLite por sala |
| 🔐 **Autenticación** | Login / Registro con Firebase Auth (Email + Contraseña) |
| 🗣️ **Asistente IA** | Chat con Gemini sobre las obras (backend en Render) |
| 📜 **Historial local** | Guarda reconocimientos con Hive (offline-first) |
| ❤️ **Favoritos** | Marca obras como favoritas |
| 🌐 **Comunidad** | Ve los reconocimientos recientes de otros usuarios (Firestore) |
| 🔊 **Text-to-Speech** | Narración de la descripción de obras en español |

---

## 🏛️ Las 6 Salas

| Sala | Temática | Obras |
|---|---|---|
| Sala 1 | Primeros Pobladores | 4 obras |
| Sala 2 | La Colonia | 4 obras |
| Sala 3 | La Independencia | 4 obras |
| Sala 4 | El Maíz | 2 obras |
| Sala 5 | Plástica Ecuatoriana | 4 obras |
| Sala 6 | La Cantonización | 3 obras |

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                    │
│                                                 │
│  Screens ──► Controllers (GetX) ──► Services   │
│                   │                    │        │
│                   ▼                    ▼        │
│             Models / State      Firebase Auth   │
│                                 Cloud Firestore │
│                                 Hive (local)    │
│                                 HTTP (backend)  │
└─────────────────────────────────────────────────┘
           │
           ▼ REST API
┌─────────────────────────┐
│   Backend (Render)      │
│   FastAPI + Gemini 1.5  │
└─────────────────────────┘
```

**Capas:**
- **Screens** — UI pura, solo llama controllers
- **Controllers** — Lógica de negocio con GetX reactive state
- **Services** — Acceso a datos (Firestore, Hive, HTTP, ML, TTS)
- **Models** — Clases de datos (`ArtworkInfo`, `RecognitionHistory`)
- **Core** — Constantes, middleware, configuración

---

## 🚀 Cómo ejecutar

### Requisitos
- Flutter SDK ≥ 3.24.0
- Android SDK
- Cuenta Firebase (con Auth + Firestore habilitados)

### Setup local

```bash
# 1. Clonar el repo
git clone https://github.com/TU_USUARIO/rumiart-ia.git
cd rumiart-ia

# 2. Instalar dependencias
flutter pub get

# 3. Generar adaptadores Hive
dart run build_runner build --delete-conflicting-outputs

# 4. Subir datos iniciales a Firestore (solo la primera vez)
dart run scripts/seed_firestore.dart

# 5. Correr la app
flutter run --dart-define=AI_BACKEND_URL=https://rumiart-ia-backend.onrender.com
```

> ⚠️ `google-services.json` no está incluido en el repo. Descárgalo desde Firebase Console y colócalo en `android/app/`.

---

## 🌐 Backend IA

El backend está en `backend/` y se despliega en [Render](https://render.com).

```bash
# Desarrollo local del backend
cd backend
pip install -r requirements.txt
GEMINI_API_KEY=tu_clave uvicorn main:app --reload
```

**Deploy en Render:**
1. Conecta tu repo a Render
2. Render detecta el `render.yaml` automáticamente
3. Agrega la variable de entorno `GEMINI_API_KEY` en el dashboard de Render

---

## 🔑 Variables de entorno / Secrets

| Variable | Dónde | Descripción |
|---|---|---|
| `GEMINI_API_KEY` | Render dashboard | API key de Google AI Studio |
| `GOOGLE_SERVICES_JSON` | GitHub Secrets (base64) | Contenido de google-services.json |
| `AI_BACKEND_URL` | GitHub Secrets | URL del backend en Render |

### Codificar google-services.json para GitHub Secrets

```bash
base64 -i android/app/google-services.json
# Copia el resultado y pégalo en GitHub → Settings → Secrets → GOOGLE_SERVICES_JSON
```

---

## 🔁 CI/CD con GitHub Actions

| Workflow | Trigger | Acción |
|---|---|---|
| `ci.yml` | Push a `main`/`develop` o PR | `flutter analyze` + `flutter test` |
| `release.yml` | Push de tag `v*` | Build APK release + publica en GitHub Releases |

### Publicar nueva versión

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 🛡️ Seguridad

- Las API keys **nunca** se incluyen en el código fuente
- `google-services.json` está en `.gitignore`
- El backend maneja la API key de Gemini (no el cliente)
- Las reglas de Firestore garantizan que cada usuario solo puede escribir sus propios logs

---

## 📂 Estructura del proyecto

```
museum_vision_app/
├── .github/workflows/     ← CI/CD (ci.yml, release.yml)
├── android/app/           ← google-services.json (NO en git)
├── assets/
│   ├── models/            ← Modelos TFLite por sala
│   └── images/            ← Logos
├── backend/               ← FastAPI + Gemini (deploy en Render)
├── lib/
│   ├── controllers/       ← GetX controllers (auth, artwork, ai, history)
│   ├── core/
│   │   ├── constants/     ← AppConstants
│   │   └── middleware/    ← AuthMiddleware
│   ├── models/            ← ArtworkInfo, RecognitionHistory
│   ├── screens/           ← Pantallas (welcome, login, register, home, history, ai_chat)
│   ├── services/          ← ML, TTS, Firestore, LocalStorage, AI Assistant
│   ├── widgets/states/    ← LoadingWidget, EmptyWidget, ErrorWidget
│   ├── firebase_options.dart
│   └── main.dart
├── scripts/
│   └── seed_firestore.dart ← Sube las 19 obras a Firestore (correr una vez)
├── firestore.rules
├── AGENTS.md
└── README.md
```

---

## 👤 Autor

Proyecto Final — Curso Flutter e IA  
**Museo y Centro Cultural Rumiñahui** · Ecuador · 2026
