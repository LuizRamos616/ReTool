import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static const bool useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: false);
  static const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '127.0.0.1');

  static const int authPort = 9099;
  static const int firestorePort = 8181;
  static const int storagePort = 9199;

  static const FirebaseOptions emulatorOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: 'demo-retool',
    messagingSenderId: '123456789',
    projectId: 'demo-retool',
    authDomain: 'demo-retool.firebaseapp.com',
    storageBucket: 'demo-retool.appspot.com',
  );

  static FirebaseOptions get currentOptions {
    if (useEmulators) {
      return emulatorOptions;
    }
    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'),
      appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: 'demo-retool'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-retool'),
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'demo-retool.firebaseapp.com'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'demo-retool.appspot.com'),
    );
  }
}

