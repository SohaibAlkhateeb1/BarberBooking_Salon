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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD4cpdjsvyDbuGymXUreJtM6xZ5RpbpaU8',
    appId: '1:886432509232:web:FIXME_WEB_APP_ID',
    messagingSenderId: '886432509232',
    projectId: 'barber-booking-c5fd6',
    storageBucket: 'barber-booking-c5fd6.firebasestorage.app',
    authDomain: 'barber-booking-c5fd6.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4cpdjsvyDbuGymXUreJtM6xZ5RpbpaU8',
    appId: '1:886432509232:android:136fceac6e3b9bec39ecf5',
    messagingSenderId: '886432509232',
    projectId: 'barber-booking-c5fd6',
    storageBucket: 'barber-booking-c5fd6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'FIXME_IOS_API_KEY',
    appId: 'FIXME_IOS_APP_ID',
    messagingSenderId: '886432509232',
    projectId: 'barber-booking-c5fd6',
    storageBucket: 'barber-booking-c5fd6.firebasestorage.app',
    iosBundleId: 'com.barberbooking.barberBooking',
  );
}
