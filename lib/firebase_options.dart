// Generated via `flutterfire configure --project=agri-billing` for
// android/web. iOS is not yet configured (no Xcode project scaffolded).
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('Platform not configured');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCdyS8i5GQYW5lFRHvrCuUI8EikQHsjNE4',
    appId: '1:766010886310:web:391a895069e5abaab80c67',
    messagingSenderId: '766010886310',
    projectId: 'agri-billing',
    authDomain: 'agri-billing.firebaseapp.com',
    storageBucket: 'agri-billing.firebasestorage.app',
    measurementId: 'G-SL9J23FMFR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmR6T_kr8WFTdpcVjhGFAlQsJq6RpNe70',
    appId: '1:766010886310:android:4250363719eb52deb80c67',
    messagingSenderId: '766010886310',
    projectId: 'agri-billing',
    storageBucket: 'agri-billing.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.terratrack.app',
  );
}
