import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Top-level function (required — closures are not sendable to isolates).
/// Overrides the SQLite library path for Linux where libsqlite3.so is only
/// available via libsqlite3-dev. Uses the versioned .so.0 that ships with
/// libsqlite3-0 (always installed, no -dev package required).
void _ffiInitLinux() {
  open.overrideFor(
    OperatingSystem.linux,
    () => DynamicLibrary.open('libsqlite3.so.0'),
  );
}

/// Call once in setUpAll() or at the top of any test file that opens a database.
/// Required for unit tests on non-mobile platforms (Windows, Linux, macOS, CI).
///
/// On Linux, uses createDatabaseFactoryFfi(ffiInit:) so the library override
/// runs inside the sqflite worker isolate (where the load actually happens).
void initSqfliteForTests() {
  if (Platform.isLinux) {
    databaseFactory = createDatabaseFactoryFfi(ffiInit: _ffiInitLinux);
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
