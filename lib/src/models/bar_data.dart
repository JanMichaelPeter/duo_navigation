import 'package:flutter/widgets.dart';

import '../geometry/layout_mode.dart';
import '../geometry/side.dart';
import 'action.dart';
import 'enums.dart';

/// Renders an action at a placement with the configured action builder.
typedef DockActionWidgetBuilder<A> =
    Widget Function(DockAction<A> action, DockActionPlacement placement);

/// What a page's title bar should show in the current mode.
///
/// In wide mode the actions that moved into the side column are in [hoisted]
/// and already rendered there; [leading] and [trailing] hold what stays in the
/// bar: label-only actions and actions with `hoist: DockHoist.never`.
@immutable
class DockBarData<A> {
  /// Built by `DockPage`; you receive it in page builders.
  const DockBarData({
    required this.mode,
    required this.title,
    required this.leading,
    required this.trailing,
    required this.hoisted,
    this.sideColumnSide,
    required DockActionWidgetBuilder<A> buildAction,
  }) : _buildAction = buildAction;

  /// The current layout mode.
  final DockLayoutMode mode;

  /// The page title.
  final Widget? title;

  /// The back or close action for the bar. Null in wide mode when it moved
  /// into the column; a text-only leading action ("Cancel") stays here in
  /// every mode.
  final DockAction<A>? leading;

  /// Actions for the bar. In wide mode only the ones that stay in the bar;
  /// the rest are in [hoisted].
  final List<DockAction<A>> trailing;

  /// Actions shown as side-column chips (wide mode only). Already rendered
  /// by the column; for information.
  final List<DockAction<A>> hoisted;

  /// Edge the side column is on in wide mode; null in compact mode.
  final DockSide? sideColumnSide;
  final DockActionWidgetBuilder<A> _buildAction;

  /// Whether the layout is [DockLayoutMode.wide].
  bool get isWide => mode == DockLayoutMode.wide;

  /// Whether [trailing] belongs at the start of the bar: the column is at the
  /// start edge, so bar actions follow it to the same side.
  bool get trailingAtStart => sideColumnSide == DockSide.start;

  /// Renders an action with the configured action builder.
  Widget buildAction(DockAction<A> action, DockActionPlacement placement) =>
      _buildAction(action, placement);
}
