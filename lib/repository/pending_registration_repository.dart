import 'package:flutter/foundation.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/repository/json_collection.dart';

/// Thin adapter over [JsonCollection] for `pending_registrations.json`.
class PendingRegistrationRepository {
  PendingRegistrationRepository._(this._collection);

  static late PendingRegistrationRepository instance;

  static const String databaseFilename = 'pending_registrations.json';

  final JsonCollection<PendingRegistration> _collection;

  /// Notifies after every successful write — pages that used to poll a
  /// hand-rolled revision counter watch this instead.
  Listenable get listenable => _collection;

  static Future<PendingRegistrationRepository> initialize({
    required String rootDir,
  }) async {
    final collection = JsonCollection<PendingRegistration>(
      rootDir: rootDir,
      fileName: databaseFilename,
      collectionKey: 'registrations',
      fromJson: PendingRegistration.fromJson,
      toJson: (registration) => registration.toJson(),
      idOf: (registration) => registration.id,
    );
    await collection.load();
    return PendingRegistrationRepository._(collection);
  }

  Iterable<PendingRegistration> getAll() => _collection.all();

  Future<void> add(PendingRegistration registration) =>
      _collection.upsert(registration);

  Future<void> delete(String id) => _collection.remove(id);
}
