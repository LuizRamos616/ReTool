import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/config/firebase_config.dart';

class FirebaseDataSource {
  static FirebaseApp? _defaultApp;
  static FirebaseApp? _secondaryApp;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _defaultApp = await Firebase.initializeApp(
        options: FirebaseConfig.currentOptions,
      );

      if (FirebaseConfig.useEmulators) {
        FirebaseAuth.instance.useAuthEmulator(FirebaseConfig.emulatorHost, FirebaseConfig.authPort);
        FirebaseFirestore.instance.useFirestoreEmulator(FirebaseConfig.emulatorHost, FirebaseConfig.firestorePort);
        FirebaseStorage.instance.useStorageEmulator(FirebaseConfig.emulatorHost, FirebaseConfig.storagePort);
      }
      _initialized = true;
    } catch (e) {
      // In tests or mock environments, Firebase might not connect to live backend
      // ignore: avoid_print
      print('FirebaseDataSource initialize note: $e');
    }
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  static Future<FirebaseApp> getSecondaryApp() async {
    if (_secondaryApp != null) return _secondaryApp!;
    try {
      _secondaryApp = await Firebase.initializeApp(
        name: 'retool-user-provisioning',
        options: FirebaseConfig.currentOptions,
      );
      if (FirebaseConfig.useEmulators) {
        FirebaseAuth.instanceFor(app: _secondaryApp!).useAuthEmulator(
          FirebaseConfig.emulatorHost,
          FirebaseConfig.authPort,
        );
      }
    } catch (_) {
      _secondaryApp = Firebase.app('retool-user-provisioning');
    }
    return _secondaryApp!;
  }
}

