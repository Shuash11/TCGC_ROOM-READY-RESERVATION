import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for web - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  // To get your web API key: Go to Firebase Console → Project Settings → Your apps → Web app
  // For now using Android API key - replace with web API key for production
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAVab2wXtsbFNtD0rFuRG1VJg2f-galjXU",
    appId: "1:1077229952205:web:733639fcef030f8ea19d84",
    messagingSenderId: "1077229952205",
    projectId: "room-ready-7f663",
    authDomain: "room-ready-7f663.firebaseapp.com",
    storageBucket: "room-ready-7f663.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAVab2wXtsbFNtD0rFuRG1VJg2f-galjXU",
    appId: "1:1077229952205:android:733639fcef030f8ea19d84",
    messagingSenderId: "1077229952205",
    projectId: "room-ready-7f663",
    storageBucket: "room-ready-7f663.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    iosClientId: "YOUR_IOS_CLIENT_ID",
    iosBundleId: "com.example.kaye",
  );
}