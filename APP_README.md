# I'll Do It - Flutter App

A South African work and hustle platform mobile application built with Flutter.

## Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── constants/       # Constants (colors, strings, etc.)
│   ├── errors/          # Custom exceptions
│   ├── extensions/      # Dart extensions
│   ├── network/         # Network services
│   ├── router/          # Navigation routing
│   ├── services/        # Core services
│   ├── theme/           # App theming
│   ├── utils/           # Utility functions
│   └── widgets/         # Reusable widgets
├── features/
│   ├── auth/            # Authentication feature
│   ├── home/            # Home feature
│   ├── explore/         # Explore feature
│   ├── services/        # Services feature
│   ├── jobs/            # Jobs feature
│   ├── chat/            # Chat/Messaging feature
│   ├── wallet/          # Wallet/Payment feature
│   ├── profile/         # User profile feature
│   └── splash/          # Splash screen
└── main.dart            # App entry point
```

## Features

### MVP Phase 1
- [x] Authentication (Email, Google, Phone)
- [x] User Profiles
- [x] Service Listings
- [x] Job Requests
- [x] Messaging System (UI)
- [x] Search & Discovery
- [x] Ratings & Reviews
- [x] Wallet System
- [x] Notifications

### Planned Features
- [ ] Advanced messaging with voice notes
- [ ] Video calling
- [ ] Live maps & location tracking
- [ ] Payment processing
- [ ] ID verification
- [ ] Scam reporting & dispute system
- [ ] Analytics dashboard
- [ ] Learning hub

## Getting Started

### Prerequisites
- Flutter 3.0 or higher
- Dart 3.0 or higher
- Android Studio / Xcode

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd it_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Supabase:
   - Create a Supabase project
   - Add your Supabase URL and Anon Key to `lib/core/config/app_config.dart`

4. Run the app:
```bash
flutter run
```

## Architecture

This project follows a **Feature-Based Architecture** with Clean Architecture principles:

### Layers
- **Presentation**: UI screens, widgets, and state management
- **Domain**: Business logic and use cases
- **Data**: Data sources, repositories, and models

### State Management
- Riverpod for dependency injection and state management
- Freezed for immutable model generation

## Design Language

### Colors
- **Primary**: Yellow (#FFD700)
- **Background**: Dark (#0F0F0F)
- **Surface**: Dark Gray (#1A1A1A)
- **Text Primary**: White (#FFFFFF)
- **Text Secondary**: Light Gray (#B3B3B3)

### Components
- Rounded corners (12-20px border radius)
- Large, accessible buttons
- Dark mode first design
- Mobile-first responsive layout

## Technology Stack

- **Flutter**: UI framework
- **Supabase**: BaaS (authentication, database, real-time)
- **Riverpod**: State management & DI
- **GoRouter**: Navigation
- **Dio**: HTTP client
- **Firebase Messaging**: Push notifications
- **Freezed**: Code generation for models

## Environment Setup

Create `.env` file (not version controlled):
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

## Development Guidelines

### Naming Conventions
- Screens: `<Feature>Screen` (e.g., `LoginScreen`, `HomeScreen`)
- Widgets: `_<WidgetName>` (private) or `<WidgetName>` (public)
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`

### Code Style
- Follow Dart style guide
- Use const constructors
- Keep widgets lightweight
- Use meaningful variable names
- Add comments for complex logic

### Git Workflow
1. Create feature branch: `feature/feature-name`
2. Commit with meaningful messages: `feat: add login screen`
3. Create pull request
4. Request review before merging

## Future Enhancements

- [ ] Dark/Light theme toggle
- [ ] Multiple language support
- [ ] Offline functionality
- [ ] Advanced analytics
- [ ] Team/Agency management
- [ ] Skills certification system
- [ ] Learning platform integration
- [ ] Creator monetization features

## Troubleshooting

### Dependencies not updating
```bash
flutter pub upgrade
flutter pub get
```

### Build issues
```bash
flutter clean
flutter pub get
flutter run
```

### Supabase connection issues
- Verify API credentials in `app_config.dart`
- Check internet connection
- Ensure Supabase project is active

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with meaningful commits
4. Push to branch
5. Create pull request

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Clean Architecture Flutter](https://codewithandrea.com/flutter-state-management/)

## License

This project is proprietary and confidential.

## Contact

For questions or support, contact the development team at support@illdoit.co.za

---

**Happy coding! 🚀**
