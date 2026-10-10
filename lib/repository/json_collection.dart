import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// A keyed, in-memory-cached collection backed by one JSON file.
///
/// Owns everything a JSON-file-backed collection does: load the file once,
/// hold the cache, serve synchronous reads from it, and persist writes
/// durably and asynchronously. [PlayerRepository], [GameRepository] and
/// friends are thin adapters over this — see `lib/CLAUDE.md`.
///
/// A write goes to a temp file, is flushed, then renamed over the target, so
/// a crash mid-write leaves the previous file intact. Writes issued while
/// one is already in flight coalesce into a single follow-up write of the
/// latest cache state, so a burst of changes costs at most two disk writes.
class JsonCollection<V> extends ChangeNotifier {
  JsonCollection({
    required this.rootDir,
    required this.fileName,
    required this.collectionKey,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  final String rootDir;
  final String fileName;

  /// The top-level JSON key the item list is stored under, e.g. `'players'`.
  final String collectionKey;

  final V Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(V) toJson;
  final String Function(V) idOf;

  late Map<String, V> _cache;

  File get _file => File(path.join(rootDir, fileName));

  /// Loads the file into the cache. Call once, before any read or write.
  Future<void> load() async {
    final file = _file;
    if (!await file.exists()) {
      _cache = {};
      return;
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final items = (json[collectionKey] as List).cast<Map<String, dynamic>>();
    _cache = {for (final item in items.map(fromJson)) idOf(item): item};
  }

  V? byId(String id) => _cache[id];

  Iterable<V> all() => _cache.values;

  Future<void> upsert(V value) => upsertAll([value]);

  Future<void> upsertAll(Iterable<V> values) {
    for (final value in values) {
      _cache[idOf(value)] = value;
    }
    return _persist();
  }

  Future<void> remove(String id) {
    _cache.remove(id);
    return _persist();
  }

  Future<void>? _activeWrite;
  Completer<void>? _pending;

  /// Enqueues a write of the current cache. Coalesces with an in-flight
  /// write: callers that arrive while one is running all await the same
  /// follow-up write instead of each triggering their own.
  Future<void> _persist() {
    if (_activeWrite != null) {
      return (_pending ??= Completer<void>()).future;
    }
    final completer = Completer<void>();
    _activeWrite = _runWrite(completer);
    return completer.future;
  }

  Future<void> _runWrite(Completer<void> completer) async {
    try {
      await _writeToDisk();
      notifyListeners();
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
    }
    final pending = _pending;
    _pending = null;
    _activeWrite = pending == null ? null : _runWrite(pending);
  }

  Future<void> _writeToDisk() async {
    await Directory(rootDir).create(recursive: true);
    final tmpFile = File(path.join(rootDir, '$fileName.tmp'));
    final body = jsonEncode({
      collectionKey: _cache.values.map(toJson).toList(),
    });
    await tmpFile.writeAsString(body, flush: true);
    await tmpFile.rename(_file.path);
  }
}
