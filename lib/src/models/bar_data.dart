import 'package:flutter/widgets.dart';

import 'action.dart';
import 'enums.dart';

/// Renders an action at a placement with the configured action builder.
typedef DockActionWidgetBuilder =
    Widget Function(DockAction action, DockActionPlacement placement);

/// What a page's title bar should show in the current mode.
///
/// In wide mode [leading] is null and [trailing] only holds the actions that
/// stay in the bar (label-only or [DockAction.pinToBar]); the rest are in
/// [hoisted] and already rendered by the side column.
@immutable
class DockBarData {
  /// Built by [DockPage]; you receive it in page builders.
  const DockBarData({
    required this.mode,
    required this.title,
    required this.leading,
    required this.trailing,
    required this.hoisted,
    this.sideColumnSide,
    required DockActionWidgetBuilder buildAction,
  }) : _buildAction = buildAction;

  /// The current layout mode.
  final DockLayoutMode mode;

  /// The page title.
  final Widget? title;

  /// Back/close action for the title bar; null in wide mode (it's a chip).
  final DockAction? leading;

  /// Actions for the title bar. In wide mode only label-only and pinned
  /// ones; the rest are in [hoisted].
  final List<DockAction> trailing;

  /// Actions shown as side-column chips (wide mode only). Already rendered
  /// by the column; for information.
  final List<DockAction> hoisted;

  /// Edge the side column is on in wide mode; null in compact mode.
  final DockSide? sideColumnSide;
  final DockActionWidgetBuilder _buildAction;

  /// Whether the layout is [DockLayoutMode.wide].
  bool get isWide => mode == DockLayoutMode.wide;

  /// Whether [trailing] belongs at the start of the bar: the column is at the
  /// start edge, so bar actions follow it to the same side.
  bool get trailingAtStart => sideColumnSide == DockSide.start;

  /// Renders an action with the configured action builder.
  Widget buildAction(DockAction action, DockActionPlacement placement) =>
      _buildAction(action, placement);
}
