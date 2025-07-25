// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSEcIDwrAvfI99L3h8a8H-wRHrV8bGgQg',
    appId: '1:731860151951:web:58b0dc102615730d0a0afa',
    messagingSenderId: '731860151951',
    projectId: 'tripexpenseapp-542a8',
    authDomain: 'tripexpenseapp-542a8.firebaseapp.com',
    storageBucket: 'tripexpenseapp-542a8.firebasestorage.app',
    measurementId: 'G-5DLS5LL2V8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0_xZt4QwNjgrP2kol-62s15TjL4QiyNU',
    appId: '1:731860151951:android:ca0050b7728b7ac50a0afa',
    messagingSenderId: '731860151951',
    projectId: 'tripexpenseapp-542a8',
    storageBucket: 'tripexpenseapp-542a8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDojeXIfBEwKdVjZFm6o4Knxd5qDJsQYQ0',
    appId: '1:731860151951:ios:5095ab347c435c290a0afa',
    messagingSenderId: '731860151951',
    projectId: 'tripexpenseapp-542a8',
    storageBucket: 'tripexpenseapp-542a8.firebasestorage.app',
    iosBundleId: 'com.example.groupExpenseSplitter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDojeXIfBEwKdVjZFm6o4Knxd5qDJsQYQ0',
    appId: '1:731860151951:ios:5095ab347c435c290a0afa',
    messagingSenderId: '731860151951',
    projectId: 'tripexpenseapp-542a8',
    storageBucket: 'tripexpenseapp-542a8.firebasestorage.app',
    iosBundleId: 'com.example.groupExpenseSplitter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCSEcIDwrAvfI99L3h8a8H-wRHrV8bGgQg',
    appId: '1:731860151951:web:12a4a00eb5a568060a0afa',
    messagingSenderId: '731860151951',
    projectId: 'tripexpenseapp-542a8',
    authDomain: 'tripexpenseapp-542a8.firebaseapp.com',
    storageBucket: 'tripexpenseapp-542a8.firebasestorage.app',
    measurementId: 'G-BC270LMEFP',
  );
}
