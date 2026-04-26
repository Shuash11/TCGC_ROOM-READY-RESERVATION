import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._internal() {
    // Enable Firestore offline persistence once, early.
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  static final FirestoreService instance = FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get rooms =>
      _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get requests =>
      _db.collection('reservation_requests');
  CollectionReference<Map<String, dynamic>> get reservations =>
      _db.collection('reservations');

  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _db.runTransaction(transactionHandler, timeout: timeout);
  }
}