/// Thumb-friendly navigation for phones, foldables and tablets: tab bar +
/// app bar on compact screens, one thumb-reachable column of tabs and actions
/// docked to the screen edge on wide screens.
library;

export 'geometry.dart';
export 'src/a11y/semantics.dart';
export 'src/actions/clock.dart';
export 'src/actions/tap_guard.dart';
export 'src/builders/builders.dart';
export 'src/config/column_inset.dart';
export 'src/config/keyboard.dart';
export 'src/config/navigation.dart';
export 'src/config/navigation_data.dart';
export 'src/config/standalone.dart';
export 'src/frame/modal_scope.dart';
export 'src/frame/shell.dart';
export 'src/frame/side_column_layout.dart';
export 'src/keys.dart';
export 'src/models/action.dart';
export 'src/models/bar_data.dart' show DockActionWidgetBuilder, DockBarData;
export 'src/models/dock_badge.dart';
export 'src/models/dock_icon.dart';
export 'src/models/enums.dart';
export 'src/models/tab.dart';
export 'src/models/tabs_data.dart';
export 'src/page.dart';
export 'src/page/bar_layout.dart';
export 'src/page/page_scope.dart';
export 'src/tabs/tab_item.dart' show DockTabBarSemantics;
export 'src/tabs/tab_stack.dart';
