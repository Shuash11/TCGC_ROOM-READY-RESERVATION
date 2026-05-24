import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform.',
        );
    }
  }

  // ── Platform-specific options ────────────────────

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _env('FIREBASE_WEB_API_KEY'),
    appId: _env('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    authDomain: _env('FIREBASE_WEB_AUTH_DOMAIN'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _env('FIREBASE_ANDROID_API_KEY'),
    appId: _env('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get ios => throw UnsupportedError(
    'iOS is not configured. Build for Android or Web instead, '
    'or set up Firebase for iOS in the Firebase Console.',
  );

  // ── Helper ───────────────────────────────────────

  /// Read a value from the .env file. Throws if missing.
  static String _env(String key) {
    if (dotenv.env.isEmpty) {
      throw Exception(
        '.env file not loaded. Make sure .env exists at the project root '
        'and is listed in pubspec.yaml under flutter > assets.',
      );
    }
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception(
        'Missing Firebase config "$key" in .env file. '
        'Copy .env.example to .env and fill in your Firebase credentials.',
      );
    }
    return value;
  }
}
