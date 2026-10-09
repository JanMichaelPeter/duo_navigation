import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:duo_navigation/duo_navigation.dart';
import 'package:duo_navigation_window_placement/duo_navigation_window_placement.dart';

import 'pages/items_page.dart';
import 'pages/map_page.dart';
import 'pages/profile_page.dart';
import 'style/custom_style.dart';
import 'tabs_home.dart' show TabAccent, tabs;

/// The same app with go_router: `flutter run -t lib/main_go_router.dart`.
///
/// `StatefulShellRoute.indexedStack` keeps one navigator per tab and puts
/// inactive tabs under `TickerMode(enabled: false)`, which is all a
/// `DuoShell` needs. Pages are the same as in `main.dart`.
void main() => runApp(const GoRouterExampleApp());

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/items',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              DuoShell<TabAccent, Object?, Object?>(
            tabs: tabs,
            currentIndex: shell.currentIndex,
            // A tap on the current tab goes back to its first page.
            onTabSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            child: shell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/items',
                  builder: (context, state) => const ItemsPage(depth: 0),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                    path: '/map', builder: (context, state) => const MapPage())
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                    path: '/profile',
                    builder: (context, state) => const ProfilePage()),
              ],
            ),
          ],
        ),
      ],
    );

class GoRouterExampleApp extends StatefulWidget {
  const GoRouterExampleApp({super.key});

  @override
  State<GoRouterExampleApp> createState() => _GoRouterExampleAppState();
}

class _GoRouterExampleAppState extends State<GoRouterExampleApp> {
  final _router = _buildRouter();
  final _windowEdges = WindowPlacementEdgesSource();

  @override
  void dispose() {
    _router.dispose();
    _windowEdges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'duo_navigation with go_router',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      routerConfig: _router,
      builder: (context, child) => DuoNavigation(
        builders: CustomStyle.builders,
        data: CustomStyle.data(
          DuoNavigationData(
            layoutPolicy: const DuoLayoutPolicy.breakpoint(466),
            windowEdgesSource: _windowEdges,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
