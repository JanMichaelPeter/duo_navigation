/// Material 3 visuals for nav_dock: [DockMaterialBuilders] sets every builder,
/// [DockMaterial] has the functions behind them, and [DockAppBar] is the title
/// bar for pages with their own `Scaffold`.
///
/// It exports `package:nav_dock/nav_dock.dart` too, so a Material app needs
/// one import:
///
/// ```dart
/// import 'package:nav_dock/material.dart';
///
/// DockNavigation(builders: const DockMaterialBuilders(), child: ...)
/// ```
library;

export 'nav_dock.dart';
export 'src/material/app_bar.dart';
export 'src/material/defaults.dart';
