/// Reports where built items are, in the scroll view's coordinates.
abstract interface class ItemLocator {
  /// Scroll offset of the leading edge of item [index] if it is built,
  /// otherwise null.
  double? scrollOffsetOfBuiltItem(int index);

  /// Extent of the viewport along the main axis, or null before layout.
  double? get viewportExtent;

  /// Extent of everything before this sliver in the scroll view.
  double get precedingScrollExtent;
}

/// Lets the render object publish itself as an [ItemLocator] without the
/// engine holding a reference to render objects directly.
final class ItemLocatorSlot {
  /// The current locator, or null while the sliver is not attached.
  ItemLocator? locator;
}
