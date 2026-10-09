import 'package:flutter/material.dart';
import 'package:duo_navigation/duo_navigation.dart';
import 'package:duo_navigation_window_placement/duo_navigation_window_placement.dart';

import 'style/custom_style.dart';
import 'tabs_home.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // Tells duo_navigation which display edges the window touches, so in split
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
      title: 'duo_navigation',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      // Above the root Navigator, so root-level modals get the config too.
      builder: (context, child) => DuoNavigation(
        // CustomStyle is optional: `builders: const DuoMaterialBuilders()`
        // (package:duo_navigation/material.dart) gives the Material defaults. See
        // style/custom_style.dart.
        builders: CustomStyle.builders,
        data: CustomStyle.data(DuoNavigationData(
          // The demo shows the column as often as it can: by window width, so
          // phones in landscape and foldables in their narrow unfolded
          // posture get it too. The default, shortestSide(600), keeps phones
          // in the bottom-bar layout.
          layoutPolicy: const DuoLayoutPolicy.breakpoint(466),
          windowEdgesSource: _windowEdges,
        )),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const TabsHome(),
    );
  }
}
