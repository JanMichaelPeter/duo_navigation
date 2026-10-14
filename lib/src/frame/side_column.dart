// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../actions/action_column.dart';
import '../actions/action_host.dart';
import '../builders/builders.dart';
import '../config/column_inset.dart';
import '../config/navigation.dart';
import '../geometry/bar_region_source.dart';
import '../geometry/bar_regions.dart';
import '../models/action.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({
    super.key,
    required this.host,
    required this.rail,
    required this.columnOnRight,
    required this.columnInset,
    required this.columnWidth,
    required this.fillsWindow,
    required this.buildChip,
  });

  final DuoActionHost host;

  /// The built rail, or null in a modal frame.
  final Widget? rail;
  final bool columnOnRight;
  final DuoColumnInset columnInset;

  /// The column's width without the system inset, the extent its bar region
  /// is asked for.
  final double columnWidth;

  /// Whether the frame covers the window, so bar regions (in window
  /// coordinates) line up with the column.
  final bool fillsWindow;

  /// Builds one action chip with the frame's typed action builder.
  final Widget Function(BuildContext context, DuoAction<Object?> action)
  buildChip;

  @override
  Widget build(BuildContext context) {
    final builders = DuoBuilders.of<Object?, Object?, Object?>(context);
    // With safeArea, the column's slot includes the system inset on its own
    // edge (cutout, button bar) and the content stays clear of it. With
    // overlap, the column is over the inset, so its builder sees none there.
    // The status bar and home indicator stay padded either way; the opposite
    // edge is not the column's concern.
    final overlap = columnInset == DuoColumnInset.overlap;
    // Over the status icons (a column of them on this edge, iPhone Duo), the
    // safe area's top is too high: start below the icons, where the bar
    // region for this edge starts.
    final regionTop = overlap && fillsWindow
        ? columnTopFromRegion(
            region: DuoNavigation.barRegionOf(
              context,
              columnOnRight ? DuoScreenEdge.right : DuoScreenEdge.left,
              columnWidth,
            ),
            onRight: columnOnRight,
            size: MediaQuery.sizeOf(context),
            padding: MediaQuery.paddingOf(context),
          )
        : null;
    final media = MediaQuery.of(context).removePadding(
      removeLeft: overlap && !columnOnRight,
      removeRight: overlap && columnOnRight,
    );
    return MediaQuery(
      data: regionTop == null
          ? media
          : media.copyWith(padding: media.padding.copyWith(top: regionTop)),
      child: SafeArea(
        left: !columnOnRight,
        right: columnOnRight,
        child: ListenableBuilder(
          listenable: host,
          builder: (context, _) => builders.buildSideColumn(
            context,
            DuoActionColumn(host: host, buildChip: buildChip),
            rail,
            host.active?.actions.any((a) => a.canHoist) ?? false,
          ),
        ),
      ),
    );
  }
}
