// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../actions/action_column.dart';
import '../actions/action_host.dart';
import '../builders/builders.dart';
import '../config/column_inset.dart';
import '../models/action.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({
    super.key,
    required this.host,
    required this.rail,
    required this.columnOnRight,
    required this.columnInset,
    required this.buildChip,
  });

  final DockActionHost host;

  /// The built rail, or null in a modal frame.
  final Widget? rail;
  final bool columnOnRight;
  final DockColumnInset columnInset;

  /// Builds one action chip with the frame's typed action builder.
  final Widget Function(BuildContext context, DockAction<Object?> action)
  buildChip;

  @override
  Widget build(BuildContext context) {
    final builders = DockBuilders.of<Object?, Object?, Object?>(context);
    // With safeArea, the column's slot includes the system inset on its own
    // edge (cutout, button bar) and the content stays clear of it. With
    // overlap, the column is over the inset, so its builder sees none there.
    // The status bar and home indicator stay padded either way; the opposite
    // edge is not the column's concern.
    final overlap = columnInset == DockColumnInset.overlap;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: overlap && !columnOnRight,
      removeRight: overlap && columnOnRight,
      child: SafeArea(
        left: !columnOnRight,
        right: columnOnRight,
        child: ListenableBuilder(
          listenable: host,
          builder: (context, _) => builders.buildSideColumn(
            context,
            DockActionColumn(host: host, buildChip: buildChip),
            rail,
            host.active?.actions.any((a) => a.canHoist) ?? false,
          ),
        ),
      ),
    );
  }
}
