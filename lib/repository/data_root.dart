import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The directory that holds the app's JSON data files.
///
/// [AppLoader] requires one, so code that starts the app must choose a
/// directory on purpose. Only `main()` uses [DataRoot.production]. Tests
/// use [DataRoot.directory] with a temp directory. See PERSISTENCE.md §6
/// phase 4.
class DataRoot {
  const DataRoot._(this._resolve);

  /// The real data directory: the documents directory, the same as the
  /// released build on `main`.
  ///
  /// Throws under `flutter test`, so a test cannot reach production data.
  factory DataRoot.production() => DataRoot._(() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      throw StateError(
        'DataRoot.production() is not permitted in tests. '
        'Use DataRoot.directory() with a temp directory.',
      );
    }
    return (await getApplicationDocumentsDirectory()).path;
  });

  /// A directory that the caller owns, for example a test sandbox.
  factory DataRoot.directory(String path) => DataRoot._(() async => path);

  final Future<String> Function() _resolve;

  /// Returns the absolute path of the data directory.
  Future<String> resolve() => _resolve();
}
