/// Abstract interface for persistent data storage.
///
/// Implementations of this interface handle the actual persistence mechanism
/// (e.g., JSON files, SQL databases) while the repository layer handles
/// in-memory caching and business logic.
abstract class DataSource<V> {
  /// Load all stored entities from the persistent storage.
  Future<Iterable<V>> loadAll();

  /// Save all entities to the persistent storage.
  /// This replaces all existing data with the provided entities.
  Future<void> saveAll(Iterable<V> data);
}
