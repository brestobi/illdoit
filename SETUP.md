# I'll Do It - Setup Instructions

## Initial Setup

### 1. Supabase Configuration

1. Create a Supabase account at https://supabase.com
2. Create a new project
3. Go to Project Settings → API
4. Copy your **Project URL** and **Anon Key**
5. Update `lib/core/config/app_config.dart`:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 2. Database Setup

Run these SQL queries in the Supabase SQL editor:

```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  display_name VARCHAR(255) NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  location VARCHAR(255),
  skills TEXT[] DEFAULT ARRAY[]::TEXT[],
  rating DECIMAL(3,1) DEFAULT 0,
  completed_jobs INT DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Services table
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  delivery_time INT NOT NULL,
  images TEXT[] DEFAULT ARRAY[]::TEXT[],
  rating DECIMAL(3,1) DEFAULT 0,
  total_orders INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Jobs table
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  budget DECIMAL(10,2) NOT NULL,
  deadline TIMESTAMP NOT NULL,
  status VARCHAR(50) DEFAULT 'open',
  images TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Reviews table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  type VARCHAR(50) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  reference VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Storage setup
-- Run these in the Storage section:
-- Create bucket: 'avatars' (Public)
-- Create bucket: 'service-images' (Public)
-- Create bucket: 'job-images' (Public)
```

### 3. Authentication Setup

1. Go to Authentication → Providers
2. Enable Email Provider
3. Enable Google OAuth (add your credentials)
4. Configure Redirect URLs:
   - `io.supabase.flutter://callback`
   - `http://localhost:3000`

### 4. RLS Policies

Navigate to Authentication → Policies and set up row-level security:

```sql
-- Users: Allow read all, write own
CREATE POLICY "Users can view their own profile"
ON users FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE USING (auth.uid() = id);

-- Services: Allow read all, write own
CREATE POLICY "Services are readable"
ON services FOR SELECT USING (true);

CREATE POLICY "Users can create services"
ON services FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their services"
ON services FOR UPDATE USING (auth.uid() = user_id);

-- Messages: Both participants can read/write
CREATE POLICY "Users can view messages as sender or receiver"
ON messages FOR SELECT 
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
ON messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id);
```

### 5. Environment Variables

Create `.env` file in project root:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

If you want to enable Yoco payments, add your Yoco secret key here as well:

```
YOCO_SECRET_KEY=your_yoco_secret_key
```

The app calls a Supabase Edge Function to create the Yoco checkout session, so the secret key stays on the backend.

### 6. Dependencies

```bash
flutter pub get
```

### 7. Code Generation

```bash
flutter pub run build_runner build
```

## Running the App

```bash
flutter run
```

For web:
```bash
flutter run -d chrome
```

For Android:
```bash
flutter run -d android
```

For iOS:
```bash
flutter run -d ios
```

## Development Commands

### Get dependencies
```bash
flutter pub get
```

### Run tests
```bash
flutter test
```

### Generate code
```bash
flutter pub run build_runner build
```

### Watch for changes
```bash
flutter pub run build_runner watch
```

### Clean build
```bash
flutter clean
flutter pub get
flutter run
```

### Format code
```bash
dart format lib/
```

### Analyze code
```bash
flutter analyze
```

## Project Configuration

### App Icons
Replace launcher icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### App Names
Update in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### Package Names
Update in `pubspec.yaml` before first release

## Building for Release

### Android
```bash
flutter build apk
flutter build appbundle
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

## Common Issues

### Supabase Connection Fails
- Verify credentials in `app_config.dart`
- Check internet connection
- Ensure Supabase project is active

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Code Generation Issues
```bash
flutter pub run build_runner clean
flutter pub run build_runner build
```

## Next Steps

1. Complete authentication flow
2. Implement service listing
3. Add messaging functionality
4. Integrate payment system
5. Add push notifications
6. Deploy to app stores

---

For more help, see the main README.md
