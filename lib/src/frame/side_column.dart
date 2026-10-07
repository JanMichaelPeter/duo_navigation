// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../actions/action_column.dart';
import '../actions/action_host.dart';
import '../builders/builders.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({
    super.key,
    required this.host,
    required this.rail,
    required this.columnOnRight,
  });

  final DockActionHost host;

  /// The built rail, or null in a modal frame.
  final Widget? rail;
  final bool columnOnRight;

  @override
  Widget build(BuildContext context) {
    final builders = DockBuilders.of<Object?>(context);
    // The column's slot includes the system inset on its own edge (cutout,
    // gesture strip); the content stays clear of it and of the status bar and
    // home indicator. The opposite edge is not the column's concern.
    return SafeArea(
      left: !columnOnRight,
      right: columnOnRight,
      child: ListenableBuilder(
        listenable: host,
        builder: (context, _) => builders.buildSideColumn(
          context,
          DockActionColumn(host: host),
          rail,
          host.active?.actions.any((a) => a.canHoist) ?? false,
        ),
      ),
    );
  }
}
