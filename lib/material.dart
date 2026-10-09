/// Material 3 visuals for duo_navigation: [DuoMaterialBuilders] sets every builder,
/// [DuoMaterial] has the functions behind them, and [DuoAppBar] is the title
/// bar for pages with their own `Scaffold`.
///
/// It exports `package:duo_navigation/duo_navigation.dart` too, so a Material app needs
/// one import:
///
/// ```dart
/// import 'package:duo_navigation/material.dart';
///
/// DuoNavigation(builders: const DuoMaterialBuilders(), child: ...)
/// ```
library;

export 'duo_navigation.dart';
export 'src/material/app_bar.dart';
export 'src/material/defaults.dart';
