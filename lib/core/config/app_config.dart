/// Application Configuration
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://bvnaffajgxxylatshlwc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2bmFmZmFqZ3h4eWxhdHNobHdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4OTU1NDIsImV4cCI6MjA5MzQ3MTU0Mn0.Ib1vWx9ODdonbPhdWttW10Z_r4oX6BI7V2ml3IhqU0s';

  // API Configuration
  static const String apiBaseUrl = 'YOUR_API_BASE_URL';
  static const Duration apiTimeout = Duration(seconds: 30);

  // App Configuration
  static const String appName = 'I\'ll Do It';
  static const String appVersion = '1.0.0';
  static const String organisationId = 'com.illdo';

  // Feature Flags
  static const bool enableDebugMode = true;
  static const bool enableAnalytics = false;
}
