import 'package:flutter/foundation.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/repository/json_collection.dart';

/// Thin adapter over [JsonCollection] for `session_templates.json`.
class SessionTemplateRepository {
  SessionTemplateRepository._(this._collection);

  static late SessionTemplateRepository instance;

  static const String databaseFilename = 'session_templates.json';

  final JsonCollection<SessionTemplate> _collection;

  /// Notifies after every successful write.
  Listenable get listenable => _collection;

  static Future<SessionTemplateRepository> initialize({
    required String rootDir,
  }) async {
    final collection = JsonCollection<SessionTemplate>(
      rootDir: rootDir,
      fileName: databaseFilename,
      collectionKey: 'templates',
      fromJson: SessionTemplate.fromJson,
      toJson: (template) => template.toJson(),
      idOf: (template) => template.id,
    );
    await collection.load();
    return SessionTemplateRepository._(collection);
  }

  /// All templates, in the order they were saved.
  Iterable<SessionTemplate> getAll() => _collection.all();

  Future<void> add(SessionTemplate template) => _collection.upsert(template);

  Future<void> delete(String id) => _collection.remove(id);
}
