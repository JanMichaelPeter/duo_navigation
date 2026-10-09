/// Read-only layout information from duo_navigation: the layout mode, the side of
/// the column, the window edges and the frame's geometry, plus the bleed
/// widgets, without the page, action or builder types.
library;

export 'src/bleed/bleed.dart' show DuoBleed, DuoBleedItem, DuoInset;
export 'src/geometry/body_mode.dart';
export 'src/geometry/dock_geometry.dart' show DuoGeometry, DuoGeometryAspect;
export 'src/geometry/layout_mode.dart';
export 'src/geometry/layout_policy.dart';
export 'src/geometry/side.dart';
export 'src/geometry/window_edges.dart';
export 'src/geometry/window_edges_source.dart';
