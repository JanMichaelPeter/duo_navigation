import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../geometry/body_mode.dart';
import '../models/action.dart';
import 'frame.dart';

/// Frame for modally presented content: wide mode gets a side column with the
/// actions (no rail), compact mode gets nothing extra.
///
/// [DockPage] adds one automatically when it finds no scope above it (a
/// page pushed on the root navigator). Wrap a modal's own nested Navigator in
/// this explicitly so all its steps share one column, and the back button
/// stays in place between steps.
class DockModalScope<A, B> extends StatelessWidget {
  /// Frames [child] as one modal with a shared side column.
  const DockModalScope({
    super.key,
    this.bodyMode,
    this.hoisting,
    this.builders,
    required this.child,
  });

  /// Whether the body is laid out beside the column or under it. Null:
  /// `DockNavigationData.bodyMode`.
  final DockBodyMode? bodyMode;

  /// Whether icon actions of its pages move into the column in wide mode.
  /// Null: `DockNavigationData.hoisting`.
  final DockHoisting? hoisting;

  /// Builders for this modal frame only, on top of the app's; null fields
  /// fall back to them.
  final DockBuilders<Object?, A, B>? builders;

  /// The modal content, typically its own Navigator.
  final Widget child;

  @override
  Widget build(BuildContext context) => DockFrame<Object?, A, B>(
    isModal: true,
    bodyMode: bodyMode,
    hoisting: hoisting,
    builders: builders,
    child: child,
  );
}
