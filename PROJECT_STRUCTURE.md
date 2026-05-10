# Flutter Project Structure - I'll Do It

## Complete Directory Layout

```
it_app/
├── android/                          # Android native code
├── ios/                              # iOS native code
├── web/                              # Web support
├── lib/
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart       # App configuration & Supabase setup
│   │   ├── constants/
│   │   │   ├── app_colors.dart       # Color palette
│   │   │   └── app_strings.dart      # String constants
│   │   ├── errors/
│   │   │   └── app_exceptions.dart   # Custom exceptions
│   │   ├── extensions/
│   │   │   └── extensions.dart       # Dart extensions (String, DateTime, etc)
│   │   ├── models/
│   │   │   └── user.dart             # Core user model
│   │   ├── network/                  # Network configuration (placeholder)
│   │   ├── repositories/
│   │   │   └── abstract_repositories.dart  # Repository interfaces
│   │   ├── router/
│   │   │   └── app_router.dart       # GoRouter configuration
│   │   ├── services/
│   │   │   └── supabase_service.dart # Supabase integration
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Theme configuration
│   │   ├── utils/                    # Utility functions (placeholder)
│   │   └── widgets/                  # Reusable widgets (placeholder)
│   ├── features/
│   │   ├── splash/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── signup_screen.dart
│   │   │       ├── widgets/          # (Placeholder)
│   │   │       └── providers/        # (Placeholder)
│   │   ├── home/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── home_screen.dart
│   │   │       ├── widgets/          # (Placeholder)
│   │   │       └── providers/        # (Placeholder)
│   │   ├── explore/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── explore_screen.dart
│   │   │       └── widgets/          # (Placeholder)
│   │   ├── services/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── services_screen.dart
│   │   │       └── widgets/          # (Placeholder)
│   │   ├── jobs/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── jobs_screen.dart
│   │   │       └── widgets/          # (Placeholder)
│   │   ├── chat/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/         # (Placeholder)
│   │   ├── wallet/
│   │   │   ├── data/                 # (Placeholder)
│   │   │   ├── domain/               # (Placeholder)
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── wallet_screen.dart
│   │   │       └── widgets/          # (Placeholder)
│   │   └── profile/
│   │       ├── data/                 # (Placeholder)
│   │       ├── domain/               # (Placeholder)
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── profile_screen.dart
│   │           └── widgets/          # (Placeholder)
│   └── main.dart                     # App entry point
├── .gitignore
├── analysis_options.yaml              # Lint rules
├── pubspec.yaml                       # Dependencies
├── pubspec.lock                       # Lock file
├── README.md                          # Project documentation
├── SETUP.md                           # Setup instructions
├── ROADMAP.md                         # Project roadmap
└── CONTRIBUTING.md                    # Contribution guidelines
```

## File Description

### Core Files

#### `lib/main.dart`
Application entry point. Initializes Supabase and sets up the app with Riverpod provider scope.

#### `lib/core/config/app_config.dart`
Centralized configuration for:
- Supabase credentials
- API endpoints
- Feature flags
- App metadata

#### `lib/core/theme/app_theme.dart`
Complete theme definition with:
- Color scheme
- Text styles
- Button themes
- Input themes
- App bar theme

#### `lib/core/constants/app_colors.dart`
Color palette following MVP design language:
- Primary: Yellow (#FFD700)
- Dark background: (#0F0F0F)
- Surface: (#1A1A1A)
- Text colors and status colors

#### `lib/core/constants/app_strings.dart`
All hardcoded strings for UI (supports easy localization later)

#### `lib/core/router/app_router.dart`
GoRouter configuration with all routes and navigation logic

#### `lib/core/errors/app_exceptions.dart`
Custom exception classes for error handling:
- NetworkException
- AuthenticationException
- ValidationException
- ServerException
- LocalStorageException
- NotFoundException

#### `lib/core/extensions/extensions.dart`
Dart extension methods for:
- String validation and formatting
- DateTime formatting and comparisons
- Number formatting
- List and Map utilities

#### `lib/core/models/user.dart`
User data model with Equatable mixin

#### `lib/core/services/supabase_service.dart`
Supabase integration service for:
- Authentication
- Database CRUD operations
- File storage
- Real-time subscriptions

#### `lib/core/repositories/abstract_repositories.dart`
Abstract repository interfaces for dependency injection

### Feature Screens

#### Authentication
- **login_screen.dart**: Email/password and OAuth login
- **signup_screen.dart**: User registration with validation

#### Main Navigation
- **home_screen.dart**: Trending services, recent jobs, quick actions
- **explore_screen.dart**: Search and discovery with categories
- **services_screen.dart**: Manage user services
- **jobs_screen.dart**: Job management with tabs
- **profile_screen.dart**: User profile with stats
- **wallet_screen.dart**: Wallet with transactions

#### Splash Screen
- **splash_screen.dart**: App initialization and branding

## Architecture Pattern

The project uses **Clean Architecture** with feature-based organization:

```
Feature/
  ├── data/              # Data sources, repositories
  ├── domain/            # Use cases, entities
  └── presentation/      # UI, state management
```

## Current Implementation Status

### ✅ Completed
- Project structure setup
- UI screens (all MVP screens)
- Theme system
- Routing infrastructure
- Error handling
- Extensions and utilities
- Supabase service
- Repository interfaces

### 🔄 In Progress
- Riverpod state management integration
- Repository implementations
- Data models

### ⏳ Placeholder Folders
- `data/` folders in features
- `domain/` folders in features
- Core `network/`, `utils/`, `widgets/` folders

## Dependencies

Main packages included:
- **flutter_riverpod**: State management
- **supabase_flutter**: Backend
- **go_router**: Navigation
- **dio**: HTTP client
- **image_picker**: Image selection
- **permission_handler**: Permissions
- **firebase_messaging**: Push notifications
- **freezed**: Code generation
- **intl**: Internationalization

## Next Steps for Development

1. **Implement Repositories**
   - Create repository implementations in `data/` folders
   - Connect to Supabase service

2. **Add State Management**
   - Create Riverpod providers for each feature
   - Implement loading states

3. **Complete Data Layer**
   - Create models in `data/models/`
   - Create data sources in `data/sources/`

4. **Implement Business Logic**
   - Create use cases in `domain/usecases/`
   - Create entities in `domain/entities/`

5. **Connect UI to Logic**
   - Update screens to use providers
   - Add form validation
   - Implement error handling

6. **Testing**
   - Add unit tests
   - Add widget tests
   - Add integration tests

## Code Organization Best Practices

1. **Keep screens focused** - Max 300 lines per screen
2. **Extract widgets** - Reusable components in `_buildWidget()` methods
3. **Use providers** - All business logic in Riverpod
4. **Follow naming** - Consistent with Dart conventions
5. **Add documentation** - Comments for complex logic
6. **Handle errors** - All network calls with try-catch

## Performance Tips

- Use `const` constructors where possible
- Implement lazy loading with pagination
- Cache images with `cached_network_image`
- Use `ListView.builder` for long lists
- Optimize images before upload

---

**Created**: May 2026
**Last Updated**: May 2026
