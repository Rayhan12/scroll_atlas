/// Precise scrolling for Flutter.
///
/// The core jump engine:
///
/// * [AtlasListView] and [SliverAtlasList], lazy lists that jump to any
///   index in one frame, with no layout of the items in between.
/// * [AtlasController], which jumps or animates to an index and alignment
///   and reports the visible span and an index based scroll fraction.
/// * [AtlasScrollbar], a thumb driven by that fraction, so it never jumps
///   back while unseen items get measured.
/// * [AtlasAnchor], which keeps the item being read in place when content
///   above it changes size or new keyed items are inserted.
library;

import 'src/list/atlas_controller.dart';
import 'src/list/atlas_list_view.dart';
import 'src/list/atlas_options.dart';
import 'src/list/atlas_scrollbar.dart';
import 'src/list/sliver_atlas_list.dart';

export 'src/core/alignment_math.dart';
export 'src/core/extent_estimator.dart';
export 'src/core/index_fraction.dart';
export 'src/core/scroll_target.dart';
export 'src/engine/list_engine.dart';
export 'src/list/atlas_controller.dart';
export 'src/list/atlas_list_view.dart';
export 'src/list/atlas_options.dart';
export 'src/list/atlas_scrollbar.dart';
export 'src/list/sliver_atlas_list.dart';
