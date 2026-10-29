/// Maps ids to the slivers registered under them. Pure Dart, so
/// the duplicate rule is tested without widgets.
final class IdRegistry<T extends Object> {
  final Map<String?, T> _entries = <String?, T>{};

  /// Registers [value] as [id] and returns null, or returns an error
  /// message naming [id] when another value already uses it. A null [id]
  /// is the unnamed entry (a single `AtlasListView`).
  String? add(String? id, T value) {
    final existing = _entries[id];
    if (existing != null && !identical(existing, value)) {
      return id == null
          ? 'Two unnamed Atlas lists share one AtlasController. Give each '
              'SliverAtlasList an id, or use one controller per list.'
          : "Two Atlas slivers use the id '$id'. Ids must be unique within "
              'one AtlasScrollView.';
    }
    _entries[id] = value;
    return null;
  }

  /// Removes [id] if it still maps to [value].
  void remove(String? id, T value) {
    if (identical(_entries[id], value)) _entries.remove(id);
  }

  /// The value registered as [id], or null.
  T? operator [](String? id) => _entries[id];

  /// Registered ids.
  Iterable<String?> get ids => _entries.keys;

  /// Registered values.
  Iterable<T> get values => _entries.values;
}
