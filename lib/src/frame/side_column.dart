import 'package:flutter/widgets.dart';

import '../actions/action_column.dart';
import '../actions/action_host.dart';
import '../config/navigation.dart';
import '../models/tabs_data.dart';

class SideColumn extends StatelessWidget {
  const SideColumn({
    super.key,
    required this.host,
    required this.tabs,
    required this.sideOnRight,
  });

  final DockActionHost host;
  final DockTabsData? tabs;
  final bool sideOnRight;

  @override
  Widget build(BuildContext context) {
    final config = DockNavigation.of(context);
    final rail = tabs == null ? null : config.railBuilder(context, tabs!);
    // Horizontal insets are ignored: the column lives in them (see
    // sideExtent). Vertical ones still keep it off status bar / home indicator.
    return SafeArea(
      left: false,
      right: false,
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
