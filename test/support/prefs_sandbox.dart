import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Replaces the preferences store with an in-memory one that holds
/// [values]. Keys are stored as given, with no `flutter.` prefix — the
/// same layout `SharedPreferencesWithCache` writes on disk.
void mockPreferences([Map<String, Object> values = const {}]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(values);
}
