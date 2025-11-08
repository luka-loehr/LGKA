// Copyright Luka Löhr 2025

/// Centralized credentials configuration for the LGKA+ app
/// 
/// These credentials are intentionally hardcoded as they provide access 
/// to school-specific public substitution plans and schedules.
/// They are NOT user-specific credentials and do not access sensitive data.
/// 
/// For security considerations:
/// - These credentials only provide read-only access to public school information
/// - No personal user data is accessed or stored using these credentials
/// - The school website requires these credentials for all public access
class AppCredentials {
  // School authentication credentials for public access
  static const String username = 'vertretungsplan';
  static const String password = 'ephraim';
  
  // Bug report form URL
  // Google Form configured to NOT collect email addresses automatically
  static const String bugReportFormUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSdknGu7-xgFurrghbUYOwoYu-Vsaftar6PGLzMv64UFpwJtRw/viewform?usp=publish-editor';
  
  // Prevent instantiation
  AppCredentials._();
}

