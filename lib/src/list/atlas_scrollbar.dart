import 'package:flutter/widgets.dart';

import 'atlas_controller.dart';

/// A scrollbar whose thumb follows items, not pixels.
///
/// A pixel scrollbar over estimated extents jumps when items get measured.
/// This thumb uses [AtlasController.scrollFraction], so it only moves
/// forward while the list moves forward. Dragging the track jumps with
/// [AtlasController.jumpToFraction]. Wrap an `AtlasListView` that uses the
/// same [controller]; the platform scrollbar is turned off underneath.
class AtlasScrollbar extends StatelessWidget {
  /// Creates the scrollbar.
  const AtlasScrollbar({
    required this.controller,
    required this.child,
    this.reverse = false,
    this.thickness = 6,
    this.minThumbExtent = 32,
    this.color = const Color(0x99000000),
    super.key,
  });

  /// Controller of the list in [child].
  final AtlasController controller;

  /// The vertical list.
  final Widget child;

  /// Set when the list is reversed, so the thumb starts at the bottom.
  final bool reverse;

  /// Thumb width; the drag area is wider.
  final double thickness;

  /// Smallest thumb height.
  final double minThumbExtent;

  /// Thumb color.
  final Color color;

  /// Width of the area that accepts drags.
  static const double dragAreaWidth = 24;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: child,
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: dragAreaWidth,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (details) =>
                    _drag(details.localPosition.dy, constraints.maxHeight),
                onVerticalDragUpdate: (details) =>
                    _drag(details.localPosition.dy, constraints.maxHeight),
                child: CustomPaint(
                  size: Size(dragAreaWidth, constraints.maxHeight),
                  painter: AtlasThumbPainter(
                    controller: controller,
                    reverse: reverse,
                    thickness: thickness,
                    minThumbExtent: minThumbExtent,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  void _drag(double dy, double height) {
    if (height <= 0) return;
    final share = AtlasThumbPainter.visibleShareOf(controller);
    final thumb = (share * height).clamp(minThumbExtent, height);
    final track = height - thumb;
    if (track <= 0) return;
    var fraction = ((dy - thumb / 2) / track).clamp(0.0, 1.0);
    if (reverse) fraction = 1 - fraction;
    controller.jumpToFraction(fraction);
  }
}

/// Paints the [AtlasScrollbar] thumb. Public for tests and custom bars.
///
/// It reads [controller] when painting, after layout, so the thumb always
/// matches the items on screen, and it repaints whenever the list scrolls.
class AtlasThumbPainter extends CustomPainter {
  /// Creates the painter.
  AtlasThumbPainter({
    required this.controller,
    required this.reverse,
    required this.thickness,
    required this.minThumbExtent,
    required this.color,
  }) : super(repaint: controller.scrollController);

  /// Controller of the list the thumb shows.
  final AtlasController controller;

  /// Whether the thumb starts at the bottom.
  final bool reverse;

  /// Thumb width.
  final double thickness;

  /// Smallest thumb height.
  final double minThumbExtent;

  /// Thumb color.
  final Color color;

  /// Share of the items of [controller] that is visible, 1 when unknown.
  static double visibleShareOf(AtlasController controller) {
    final span = controller.visibleSpan;
    final count = controller.itemCount;
    if (span == null || count == 0) return 1;
    return (span.length / count).clamp(0.0, 1.0);
  }

  /// Thumb rectangle inside [size], or null when there is nothing to show.
  Rect? thumbRect(Size size) {
    final value = controller.scrollFraction;
    final share = visibleShareOf(controller);
    if (value == null || share >= 1) return null;
    final height =
        (share * size.height).clamp(minThumbExtent, size.height).toDouble();
    final track = size.height - height;
    final position = reverse ? 1 - value : value;
    return Rect.fromLTWH(
      size.width - thickness - 2,
      track * position,
      thickness,
      height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = thumbRect(size);
    if (rect == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(AtlasThumbPainter oldDelegate) =>
      !identical(oldDelegate.controller, controller) ||
      oldDelegate.reverse != reverse ||
      oldDelegate.thickness != thickness ||
      oldDelegate.minThumbExtent != minThumbExtent ||
      oldDelegate.color != color;
}
