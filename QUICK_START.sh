#!/bin/bash

# I'll Do It - New Environment Setup Script
# This script installs dependencies and prepares the project for development.

echo "🚀 Starting setup for 'I'll Do It'..."

# 1. Check for Flutter
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter not found. Please install it from https://docs.flutter.dev/get-started/install"
    exit
fi

# 2. Check for Supabase CLI
if ! command -v supabase &> /dev/null
then
    echo "📦 Installing Supabase CLI..."
    # Using npm or direct brew/script depending on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sLo supabase.tar.gz https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz
        tar -xf supabase.tar.gz
        sudo mv supabase /usr/local/bin/
        rm supabase.tar.gz
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install supabase/tap/supabase
    fi
fi

# 3. Install Flutter Dependencies
echo "pulling Flutter dependencies..."
flutter pub get

# 4. Generate Code (Freezed, JSON Serializer)
echo "🛠 Generating code..."
dart run build_runner build --delete-conflicting-outputs

# 5. Supabase Initialization
echo "🔗 Linking to Supabase..."
echo "Enter your Supabase Project Ref (from Project Settings > General):"
read PROJECT_REF
supabase link --project-ref "$PROJECT_REF"

# 6. Push Migrations (if new database)
echo "❓ Do you want to push migrations to this project? (y/n)"
read PUSH_MIGRATIONS
if [ "$PUSH_MIGRATIONS" = "y" ]; then
    supabase db push
fi

# 7. Environment Variables Reminder
echo ""
echo "✅ Base setup complete!"
echo "----------------------------------------------------"
echo "📢 IMPORTANT: Set your secrets in Supabase Dashboard or via CLI:"
echo "supabase secrets set YOCO_SECRET_KEY=your_key"
echo "supabase secrets set FIREBASE_SERVICE_ACCOUNT='{\"project_id\": \"...\", ...}'"
echo ""
echo "To run the app: flutter run"
echo "----------------------------------------------------"
