import 'package:flutter/material.dart';

/// What a demo shows and why it matters, read by the gallery and by the
/// frame around each demo.
final class DemoSpec {
  const DemoSpec({
    required this.slug,
    required this.title,
    required this.icon,
    required this.problem,
    required this.withListView,
    required this.withAtlas,
    required this.whatToTry,
    required this.builder,
  });

  /// Route name without the slash, such as `menu` for `#/menu`.
  final String slug;

  /// Short title, such as "Food menu".
  final String title;

  /// Icon on the gallery card.
  final IconData icon;

  /// The problem in one line.
  final String problem;

  /// What breaks with a plain ListView or CustomScrollView.
  final String withListView;

  /// What scroll_atlas does instead.
  final String withAtlas;

  /// Steps to try on the screen.
  final String whatToTry;

  /// Builds the demo screen.
  final WidgetBuilder builder;

  /// Route name, such as `/menu`.
  String get route => '/$slug';
}
