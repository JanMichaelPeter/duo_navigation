import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../geometry/layout_mode.dart';
import '../geometry/layout_policy.dart';
import 'navigation.dart';
import 'navigation_data.dart';

/// A [DuoNavigation] for content that may have none above it, and nothing
/// where one exists.
///
/// `DuoPage`, `DuoPageScope`, `DuoShell` and `DuoModalScope` need a
/// [DuoNavigation] above them and fail loudly without one. An app that
/// adopts duo_navigation page by page has places where none is: a route pushed by a
/// plugin or from a second `MaterialApp`, an overlay, or a page that is shown
/// both inside and outside the migrated part of the app. Wrap such content in
/// a [DuoStandalone]:
///
/// ```dart
/// DuoStandalone(
///   builders: const DuoMaterialBuilders(),
///   child: const ItemDetailsPage(), // builds a DuoPage
/// )
/// ```
///
/// Below a [DuoNavigation] it returns [child] as it is, and [data] and
/// [builders] are not used: the app's configuration applies. Without one it
/// provides a [DuoNavigation] with [data] and [builders], by default pinned
/// to the compact layout, where a page brings its own title bar and nothing
/// else.
///
/// For widget tests use `DuoTestHarness` (`package:duo_navigation/testing.dart`)
/// instead: it also pins the mode, the window edges and the tap guard's clock
/// to the test.
class DuoStandalone extends StatelessWidget {
  /// Provides a [DuoNavigation] for [child] if there is none above.
  const DuoStandalone({
    super.key,
    this.data = compact,
    this.builders,
    required this.child,
  });

  /// The default [data]: the compact layout, whatever the window size.
  static const DuoNavigationData compact = DuoNavigationData(
    layoutPolicy: DuoLayoutPolicy.fixed(DuoLayoutMode.compact),
  );

  /// The configuration when there is no [DuoNavigation] above.
  final DuoNavigationData data;

  /// The visuals when there is no [DuoNavigation] above, for example
  /// `const DuoMaterialBuilders()` from `package:duo_navigation/material.dart`.
  final DuoBuilders<Object?, Object?, Object?>? builders;

  /// The content that needs a [DuoNavigation].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (DuoNavigation.maybeOf(context) != null) return child;
    return DuoNavigation(data: data, builders: builders, child: child);
  }
}
