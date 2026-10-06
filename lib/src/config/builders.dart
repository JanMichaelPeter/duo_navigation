import 'package:flutter/widgets.dart';

import '../models/action.dart';
import '../models/bar_data.dart';
import '../models/enums.dart';
import '../models/tabs_data.dart';

/// Builds the bottom tab bar (compact) or the rail (wide) from [DockTabsData].
typedef DockTabsBuilder =
    Widget Function(BuildContext context, DockTabsData data);

/// Builds one action; [DockActionPlacement] says whether it's in the
/// title bar or a chip in the side column.
typedef DockActionBuilder =
    Widget Function(
      BuildContext context,
      DockAction action,
      DockActionPlacement placement,
    );

/// Builds a page around its body: title bar from [DockBarData], then
/// `body`.
typedef DockPageScaffoldBuilder =
    Widget Function(BuildContext context, DockBarData bar, Widget body);

/// Arranges the side column. [actions] is the animated action stack (it
/// expands and anchors to the bottom); [tabs] is the rail, or null in modals.
/// [hasActions] is true while the active page has chips in the column, e.g.
/// to show a separator between them and the rail only when needed. It turns
/// false as soon as the chips start animating out.
typedef DockSideColumnBuilder =
    Widget Function(
      BuildContext context,
      Widget actions,
      Widget? tabs,
      bool hasActions,
    );

/// Animates a side-column chip in (0 → 1) and out (1 → 0).
typedef DockActionTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Widget child,
    );
