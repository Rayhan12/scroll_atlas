/// Drop-in names for scrollable_positioned_list 0.3.8 and
/// linked_scroll_controller 0.2.0.
///
/// Change the import, keep the code:
///
/// ```dart
/// import 'package:scroll_atlas/compat.dart';
/// ```
///
/// Every public name of both packages exists here. Parameters that
/// scroll_atlas cannot honour are marked `@Deprecated` with a pointer to
/// the new API. The README lists the main differences.
library;

export 'src/compat/linked_compat.dart';
export 'src/compat/positioned_list_compat.dart';
