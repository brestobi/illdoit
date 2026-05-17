# Project Environment Recap: I'll Do It

This document summarizes the tools, environment features, and configuration required to migrate the "I'll Do It" project to a new workspace.

## 1. Project Identity
- **Name:** ill_do_it
- **Description:** South African work and hustle platform.
- **Platform:** Flutter (iOS, Android, Web, Linux, MacOS, Windows).
- **Architecture:** Feature-based Clean Architecture.

## 2. Technology Stack
- **Frontend Framework:** Flutter (SDK '>=3.5.3 <4.0.0')
- **State Management:** Riverpod (flutter_riverpod, riverpod_generator)
- **Navigation:** GoRouter
- **Backend (BaaS):** Supabase (Auth, Database, Storage, Realtime)
- **Push Notifications:** Firebase Messaging
- **Payments:** Yoco (via Supabase Edge Functions)
- **Networking:** Dio
- **Code Generation:** Build Runner, Freezed, Json Serializable

## 3. Local Environment Requirements
- **Flutter SDK:** version 3.5.3 or higher.
- **Dart SDK:** compatible with the Flutter version.
- **Supabase CLI:** Required for managing Edge Functions and local database migrations.
- **Android Studio / Xcode:** For mobile builds.
- **VS Code:** Recommended editor with Flutter/Dart extensions.

## 4. External Services & Configuration
The following services must be configured in the new workspace:

### Supabase
- **Project URL & Anon Key:** Must be updated in lib/core/config/app_config.dart.
- **Environment Variables:** .env file in project root with SUPABASE_URL and SUPABASE_ANON_KEY.
- **Edge Functions:** 
    - yoco_checkout
    - yoco_webhook
- **Secrets:** YOCO_SECRET_KEY must be set in Supabase (supabase secrets set YOCO_SECRET_KEY=...).
- **Storage Buckets:**
    - avatars (Public)
    - service-images (Public)
    - job-images (Public)
    - verification-docs (Private)

### Firebase
- **Configuration:** firebase.json and lib/firebase_options.dart.
- **Google Services:** android/app/google-services.json and ios/Runner/GoogleService-Info.plist (if applicable).

### Yoco
- **Secret Key:** Needed for payment processing.
- **Webhook:** Pointing to the Supabase Edge Function yoco_webhook.

## 5. Database Setup
- **Schema:** Use schema.sql for a fresh setup or run migrations in supabase/migrations/.
- **Realtime:** Enabled for specific tables (as per migrations).

## 6. Core Commands
| Task | Command |
| --- | --- |
| Get Dependencies | flutter pub get |
| Code Generation | dart run build_runner build --delete-conflicting-outputs |
| Run App (Mobile) | flutter run |
| Run App (Web) | flutter run -d chrome |
| Deploy Edge Functions | supabase functions deploy <function_name> |
| Analyze Code | flutter analyze |
| Format Code | dart format . |

---
*Generated on 2026-05-17 for workspace migration.*
