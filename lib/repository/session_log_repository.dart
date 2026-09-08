import 'package:flutter/foundation.dart';
import 'package:good_bad_board/model/session_log.dart';
import 'package:good_bad_board/repository/json_collection.dart';

/// Thin adapter over [JsonCollection] for `session_logs.json`.
class SessionLogRepository {
  SessionLogRepository._(this._collection);

  static late SessionLogRepository instance;

  static const String databaseFilename = 'session_logs.json';

  final JsonCollection<SessionLog> _collection;

  /// Notifies after every successful write.
  Listenable get listenable => _collection;

  static Future<SessionLogRepository> initialize({
    required String rootDir,
  }) async {
    final collection = JsonCollection<SessionLog>(
      rootDir: rootDir,
      fileName: databaseFilename,
      collectionKey: 'logs',
      fromJson: SessionLog.fromJson,
      toJson: (log) => log.toJson(),
      idOf: (log) => log.id,
    );
    await collection.load();
    return SessionLogRepository._(collection);
  }

  Iterable<SessionLog> getAll() => _collection.all();

  Future<void> add(SessionLog log) => _collection.upsert(log);
}
