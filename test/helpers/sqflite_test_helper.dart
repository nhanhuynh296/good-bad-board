import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Call once in setUpAll() or at the top of any test file that opens a database.
/// Required for unit tests on non-mobile platforms (Windows, Linux, macOS, CI).
void initSqfliteForTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
