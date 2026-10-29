/// What an Atlas list keeps still when items above the viewport change.
enum AtlasAnchor {
  /// Keep the first visible item at the same place on screen when items
  /// above it grow, shrink, or are inserted or removed. Inserted
  /// items keep their identity only when the list has keys and a
  /// `findChildIndexCallback`.
  firstVisible,

  /// Do not compensate; content moves like in a plain `ListView`.
  none,
}

/// How `AtlasController.animateTo` covers long distances.
enum AtlasLongDistance {
  /// Animate the whole way. The path slows down exponentially near the
  /// target, so long trips glide and still end without a snap.
  glide,

  /// Jump to one viewport before the target, then animate the rest.
  jumpThenAnimate,
}
