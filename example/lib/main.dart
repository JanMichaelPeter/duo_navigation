import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

import 'style/custom_style.dart';
import 'tabs_home.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nav_dock',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      // Above the root Navigator, so root-level modals get the config too.
      // In split screen the side column follows the window to the screen
      // edge automatically.
      builder: (context, child) => DockNavigation(
        // CustomStyle is optional: plain DockNavigationData gives the
        // Material defaults. See style/custom_style.dart.
        data: CustomStyle.data(const DockNavigationData(breakpoint: 466)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const TabsHome(),
    );
  }
}
