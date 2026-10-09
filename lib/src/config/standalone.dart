import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../geometry/layout_mode.dart';
import '../geometry/layout_policy.dart';
import 'navigation.dart';
import 'navigation_data.dart';

/// A [DockNavigation] for content that may have none above it, and nothing
/// where one exists.
///
/// `DockPage`, `DockPageScope`, `DockShell` and `DockModalScope` need a
/// [DockNavigation] above them and fail loudly without one. An app that
/// adopts duo_navigation page by page has places where none is: a route pushed by a
/// plugin or from a second `MaterialApp`, an overlay, or a page that is shown
/// both inside and outside the migrated part of the app. Wrap such content in
/// a [DockStandalone]:
///
/// ```dart
/// DockStandalone(
///   builders: const DockMaterialBuilders(),
///   child: const ItemDetailsPage(), // builds a DockPage
/// )
/// ```
///
/// Below a [DockNavigation] it returns [child] as it is, and [data] and
/// [builders] are not used: the app's configuration applies. Without one it
/// provides a [DockNavigation] with [data] and [builders], by default pinned
/// to the compact layout, where a page brings its own title bar and nothing
/// else.
///
/// For widget tests use `DockTestHarness` (`package:duo_navigation/testing.dart`)
/// instead: it also pins the mode, the window edges and the tap guard's clock
/// to the test.
class DockStandalone extends StatelessWidget {
  /// Provides a [DockNavigation] for [child] if there is none above.
  const DockStandalone({
    super.key,
    this.data = compact,
    this.builders,
    required this.child,
  });

  /// The default [data]: the compact layout, whatever the window size.
  static const DockNavigationData compact = DockNavigationData(
    layoutPolicy: DockLayoutPolicy.fixed(DockLayoutMode.compact),
  );

  /// The configuration when there is no [DockNavigation] above.
  final DockNavigationData data;

  /// The visuals when there is no [DockNavigation] above, for example
  /// `const DockMaterialBuilders()` from `package:duo_navigation/material.dart`.
  final DockBuilders<Object?, Object?, Object?>? builders;

  /// The content that needs a [DockNavigation].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DockNavigation.maybeOf(context) != null) return child;
    return DockNavigation(data: data, builders: builders, child: child);
  }
}
