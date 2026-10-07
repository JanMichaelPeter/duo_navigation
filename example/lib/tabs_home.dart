import 'package:flutter/material.dart';
import 'package:nav_dock/nav_dock.dart';

import 'pages/items_page.dart';
import 'pages/map_page.dart';
import 'pages/profile_page.dart';

const _tabs = <DockTab<Object?>>[
  DockTab(
    id: 'items',
    icon: DockIcon(Icons.list_alt_outlined),
    selectedIcon: DockIcon(Icons.list_alt),
    label: 'Items',
    badge: DockBadge.count(3),
  ),
  DockTab(
    id: 'map',
    icon: DockIcon(Icons.map_outlined),
    selectedIcon: DockIcon(Icons.map),
    label: 'Map',
  ),
  DockTab(
    id: 'profile',
    icon: DockIcon(Icons.person_outline),
    selectedIcon: DockIcon(Icons.person),
    label: 'Profile',
  ),
];

/// Plain Navigator-per-tab setup. With go_router, use
/// StatefulShellRoute.indexedStack instead (see README).
class TabsHome extends StatefulWidget {
  const TabsHome({super.key});

  @override
  State<TabsHome> createState() => _TabsHomeState();
}

class _TabsHomeState extends State<TabsHome> {
  int _index = 0;
  final _keys = List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());
  static const _roots = <Widget>[ItemsPage(depth: 0), MapPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return DockShell(
      tabs: _tabs,
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      // A tap on the current tab pops it to its root.
      onTabReselected: (i) =>
          _keys[i].currentState?.popUntil((route) => route.isFirst),
      // The map tab runs under the bar and column, so this shell keeps the
      // body under the chrome; the other pages use SafeArea. The default,
      // DockBodyMode.inset, lays the body out beside the chrome instead.
      bodyMode: DockBodyMode.overlay,
      // Keeps every tab's navigator alive and the inactive ones inert.
      child: DockTabStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Navigator(
              key: _keys[i],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings, builder: (_) => _roots[i]),
            ),
        ],
      ),
    );
  }
}
