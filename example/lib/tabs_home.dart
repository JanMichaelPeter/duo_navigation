import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

import 'pages/items_page.dart';
import 'pages/map_page.dart';
import 'pages/profile_page.dart';

const _tabs = [
  DockTab(
      icon: Icon(Icons.list_alt_outlined),
      selectedIcon: Icon(Icons.list_alt),
      label: 'Items',
      data: 3), // badge count; only the custom style renders it
  DockTab(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map'),
  DockTab(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile'),
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

  void _select(int i) {
    if (i == _index) {
      _keys[i].currentState?.popUntil((r) => r.isFirst); // re-tap: pop to root
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DockShell(
      tabs: _tabs,
      currentIndex: _index,
      onTabSelected: _select,
      // The map tab runs under the bar and column, so this shell keeps the
      // body under the chrome; the other pages use SafeArea. The default,
      // DockBodyMode.inset, lays the body out beside the chrome instead.
      bodyMode: DockBodyMode.overlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Offstage(
              offstage: i != _index,
              // Required: tells DockPage which tab is visible.
              child: TickerMode(
                enabled: i == _index,
                child: Navigator(
                  key: _keys[i],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings, builder: (_) => _roots[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
