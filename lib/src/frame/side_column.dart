// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../actions/action_column.dart';
import '../actions/action_host.dart';
import '../config/navigation.dart';
import '../keys.dart';
import '../models/tabs_data.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({
    super.key,
    required this.host,
    required this.tabs,
    required this.columnOnRight,
  });

  final DockActionHost host;
  final DockTabsData? tabs;
  final bool columnOnRight;

  @override
  Widget build(BuildContext context) {
    final config = DockNavigation.of(context);
    final rail = tabs == null
        ? null
        : KeyedSubtree(
            key: DockKeys.rail,
            child: config.railBuilder(context, tabs!),
          );
    // The column's slot includes the system inset on its own edge (cutout,
    // gesture strip); the content stays clear of it and of the status bar and
    // home indicator. The opposite edge is not the column's concern.
    return SafeArea(
      left: !columnOnRight,
      right: columnOnRight,
      child: ListenableBuilder(
        listenable: host,
        builder: (context, _) => config.sideColumnBuilder(
          context,
          DockActionColumn(host: host),
          rail,
          host.active?.actions.any((a) => a.canHoist) ?? false,
        ),
      ),
    );
  }
}
