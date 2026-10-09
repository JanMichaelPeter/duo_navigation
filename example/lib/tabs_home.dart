import 'package:flutter/material.dart';
import 'package:duo_navigation/duo_navigation.dart';

import 'pages/items_page.dart';
import 'pages/map_page.dart';
import 'pages/profile_page.dart';
import 'style/custom_style.dart';

/// App data for a tab, carried as a typed payload: the custom tab item reads
/// it as `data.tab.payload` without a cast.
class TabAccent {
  const TabAccent(this.color);

  final Color color;
}

const tabs = <DockTab<TabAccent>>[
  DockTab(
    id: 'items',
    icon: DockIcon(Icons.list_alt_outlined),
    selectedIcon: DockIcon(Icons.list_alt),
    label: 'Items',
    badge: DockBadge.count(3),
    payload: TabAccent(Colors.indigo),
  ),
  DockTab(
    id: 'map',
    icon: DockIcon(Icons.map_outlined),
    selectedIcon: DockIcon(Icons.map),
    label: 'Map',
    payload: TabAccent(Colors.teal),
  ),
  DockTab(
    id: 'profile',
    icon: DockIcon(Icons.person_outline),
    selectedIcon: DockIcon(Icons.person),
    label: 'Profile',
    payload: TabAccent(Colors.deepOrange),
  ),
];

/// One DockTabNavigator per tab in a DockTabStack. With go_router, see
/// `main_go_router.dart`.
class TabsHome extends StatefulWidget {
  const TabsHome({super.key});

  @override
  State<TabsHome> createState() => _TabsHomeState();
}

class _TabsHomeState extends State<TabsHome> {
  int _index = 0;
  final _keys = List.generate(tabs.length, (_) => GlobalKey<NavigatorState>());
  static const _roots = <Widget>[ItemsPage(depth: 0), MapPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return DockShell<TabAccent, Object?, Object?>(
      tabs: tabs,
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      // A tap on the current tab pops it to its root.
      onTabReselected: (i) =>
          _keys[i].currentState?.popUntil((route) => route.isFirst),
      // Builders for this shell only, typed for its tabs: the selected tab
      // shows its accent color. Everything else comes from the app's style.
      builders: DockBuilders<TabAccent, Object?, Object?>(
        tabItem: (context, data) => CustomStyle.tabItem(
          context,
          data,
          accent: data.tab.payload?.color,
        ),
      ),
      // Keeps every tab's navigator alive and the inactive ones inert.
      child: DockTabStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            // Doesn't clip (the map page bleeds under the bar and column) and
            // handles Android's system back for the shown tab.
            DockTabNavigator(
              navigatorKey: _keys[i],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings, builder: (_) => _roots[i]),
            ),
        ],
      ),
    );
  }
}
