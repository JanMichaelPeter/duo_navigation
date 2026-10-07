import 'package:flutter/material.dart';
import 'package:nav_dock/nav_dock.dart';
import 'package:nav_dock_window_placement/nav_dock_window_placement.dart';

import 'style/custom_style.dart';
import 'tabs_home.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Tells nav_dock which display edges the window touches, so in split
  // screen the side column follows the window to the screen edge.
  final _windowEdges = WindowPlacementEdgesSource();

  @override
  void dispose() {
    _windowEdges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nav_dock',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      // Above the root Navigator, so root-level modals get the config too.
      builder: (context, child) => DockNavigation(
        // CustomStyle is optional: plain DockNavigationData gives the
        // Material defaults. See style/custom_style.dart.
        data: CustomStyle.data(DockNavigationData(
          // 466 also gives foldables in their narrow unfolded posture the
          // wide layout.
          layoutPolicy: const DockLayoutPolicy.breakpoint(466),
          windowEdgesSource: _windowEdges,
        )),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const TabsHome(),
    );
  }
}
