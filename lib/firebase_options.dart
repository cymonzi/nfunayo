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
    apiKey: 'AIzaSyAKFcPYZmnCgZO-pGJmqUPfHYv-30OLLwE',
    appId: '1:755571879517:web:6053e7d9771004d41427b4',
    messagingSenderId: '755571879517',
    projectId: 'nfunayo',
    authDomain: 'nfunayo.firebaseapp.com',
    storageBucket: 'nfunayo.firebasestorage.app',
    measurementId: 'G-KG79HCGS1L',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrrMxNvnVSrX2phV6nfXH_guQ2ZI7r3Fw',
    appId: '1:755571879517:android:a8df6269f5614cf01427b4',
    messagingSenderId: '755571879517',
    projectId: 'nfunayo',
    storageBucket: 'nfunayo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQ6deFXe4TGoVI8zc5Zsqlz_0ogLHWdR4',
    appId: '1:755571879517:ios:d90bc01ad38581cb1427b4',
    messagingSenderId: '755571879517',
    projectId: 'nfunayo',
    storageBucket: 'nfunayo.firebasestorage.app',
    iosBundleId: 'com.example.kapay',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAQ6deFXe4TGoVI8zc5Zsqlz_0ogLHWdR4',
    appId: '1:755571879517:ios:d90bc01ad38581cb1427b4',
    messagingSenderId: '755571879517',
    projectId: 'nfunayo',
    storageBucket: 'nfunayo.firebasestorage.app',
    iosBundleId: 'com.example.kapay',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAKFcPYZmnCgZO-pGJmqUPfHYv-30OLLwE',
    appId: '1:755571879517:web:603e7db3a0dff54d1427b4',
    messagingSenderId: '755571879517',
    projectId: 'nfunayo',
    authDomain: 'nfunayo.firebaseapp.com',
    storageBucket: 'nfunayo.firebasestorage.app',
    measurementId: 'G-W1JYL90SWW',
  );
}
