import 'package:scroll_atlas/experimental.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'observer_engine.dart';
import 'plain_list_view_engine.dart';
import 'positioned_list_engine.dart';
import 'super_sliver_list_engine.dart';

/// Creates a fresh engine for one scenario run.
typedef EngineFactory = ListEngine Function();

/// Every engine the benchmark compares. Adding an engine means adding one
/// line here; scenarios never name concrete engines (open/closed).
const List<EngineFactory> engineCatalog = <EngineFactory>[
  PrototypeScrollEngine.new,
  SuperSliverListEngine.new,
  PositionedListEngine.new,
  ObserverEngine.new,
  PlainListViewEngine.new,
];
