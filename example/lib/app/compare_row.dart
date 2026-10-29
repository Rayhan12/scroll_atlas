import 'package:flutter/material.dart';

import 'demo_theme.dart';

/// One line of the before and after comparison.
class CompareRow extends StatelessWidget {
  /// What goes wrong with a plain ListView.
  const CompareRow.listView(this.text, {super.key}) : good = false;

  /// What scroll_atlas does.
  const CompareRow.atlas(this.text, {super.key}) : good = true;

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = good ? scheme.primary : scheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(good ? Icons.check_circle : Icons.cancel, size: 18, color: color),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: good ? 'scroll_atlas: ' : 'ListView: ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text),
              ],
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
