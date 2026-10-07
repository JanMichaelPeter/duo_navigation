import 'package:flutter/material.dart';

import '../builders/builders.dart';
import '../config/navigation.dart';
import '../models/action.dart';
import '../models/bar_data.dart';
import '../models/enums.dart';
import '../models/tabs_data.dart';

/// Every [DockBuilders] field set to the Material 3 defaults in
/// [DockMaterial].
///
/// ```dart
/// DockNavigation(builders: const DockMaterialBuilders(), child: ...)
/// ```
///
/// Replace single builders with [DockBuilders.merge]:
/// `const DockMaterialBuilders().merge(DockBuilders(tabBar: myTabBar))`.
class DockMaterialBuilders extends DockBuilders {
  /// The Material defaults.
  const DockMaterialBuilders()
    : super(
        tabBar: DockMaterial.tabBar,
        rail: DockMaterial.rail,
        action: DockMaterial.action,
        page: DockMaterial.page,
        sideColumn: DockMaterial.sideColumn,
        actionTransition: DockMaterial.actionTransition,
      );
}

/// The Material 3 visuals behind [DockMaterialBuilders]. They are plain
/// functions: call and wrap them from your own builders instead of rewriting
/// them.
abstract final class DockMaterial {
  static const double _railPadding = 4;

  /// A Material 3 [NavigationBar] with one destination per tab.
  static Widget tabBar(BuildContext context, DockTabsData data) {
    return NavigationBar(
      selectedIndex: data.currentIndex,
      onDestinationSelected: data.onSelected,
      destinations: [
        for (final t in data.tabs)
          NavigationDestination(
            icon: t.icon,
            selectedIcon: t.selectedIcon,
            label: t.label ?? '',
            tooltip: t.tooltip,
          ),
      ],
    );
  }

  /// One vertical pill with an icon per tab, `sideItemExtent` wide.
  static Widget rail(BuildContext context, DockTabsData data) {
    final scheme = Theme.of(context).colorScheme;
    final itemExtent =
        DockNavigation.of(context).sideItemExtent - 2 * _railPadding;
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.all(_railPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < data.tabs.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _railItem(scheme, data, i, itemExtent),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _railItem(
    ColorScheme scheme,
    DockTabsData data,
    int i,
    double extent,
  ) {
    final tab = data.tabs[i];
    final selected = i == data.currentIndex;
    return IconButton(
      isSelected: selected,
      icon: tab.icon,
      selectedIcon: tab.selectedIcon ?? tab.icon,
      tooltip: tab.tooltip ?? tab.label,
      onPressed: () => data.onSelected(i),
      style: IconButton.styleFrom(
        fixedSize: Size.square(extent),
        backgroundColor: selected
            ? scheme.secondaryContainer
            : Colors.transparent,
        foregroundColor: selected
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
      ),
    );
  }

  /// Round chip in the side column; icon or text button in the bar.
  static Widget action(
    BuildContext context,
    DockAction action,
    DockActionPlacement placement,
  ) {
    final tooltip = action.tooltip ?? action.label;
    if (placement == DockActionPlacement.sideColumn) {
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: scheme.surfaceContainerHigh,
        elevation: 3,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: tooltip,
          onPressed: action.onPressed,
          icon: morphingIcon(action.icon!),
          style: IconButton.styleFrom(
            fixedSize: Size.square(DockNavigation.of(context).sideItemExtent),
          ),
        ),
      );
    }
    if (action.icon != null) {
      return IconButton(
        tooltip: tooltip,
        onPressed: action.onPressed,
        icon: morphingIcon(action.icon!),
      );
    }
    return TextButton(onPressed: action.onPressed, child: Text(action.label!));
  }

  /// Cross-fades when the icon changes (back -> close, star -> filled star).
  /// Icons are compared by IconData so rebuilding the same icon doesn't
  /// restart the animation.
  static Widget morphingIcon(Widget icon) {
    final Key key = icon is Icon
        ? ValueKey<Object?>(icon.icon)
        : ValueKey<Object>(icon.runtimeType);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(key: key, child: icon),
    );
  }

  /// Scaffold + AppBar. When the side column is at the start edge, the bar's
  /// actions move to the start too, so everything sits on one side.
  static Widget page(BuildContext context, DockBarData bar, Widget body) {
    if (bar.trailingAtStart && bar.trailing.isNotEmpty) {
      return Scaffold(appBar: _actionsAtStartAppBar(context, bar), body: body);
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: bar.leading == null
            ? null
            : bar.buildAction(bar.leading!, DockActionPlacement.barLeading),
        title: bar.title,
        actions: [
          for (final a in bar.trailing)
            bar.buildAction(a, DockActionPlacement.barTrailing),
          if (bar.trailing.isNotEmpty) const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }

  // Wide mode only, so there is no leading action (it's in the column).
  static PreferredSizeWidget _actionsAtStartAppBar(
    BuildContext context,
    DockBarData bar,
  ) {
    final theme = Theme.of(context);
    final actions = [
      for (final a in bar.trailing)
        bar.buildAction(a, DockActionPlacement.barTrailing),
    ];
    final centered =
        theme.appBarTheme.centerTitle ??
        switch (theme.platform) {
          TargetPlatform.iOS || TargetPlatform.macOS => true,
          _ => false,
        };

    if (!centered) {
      // Start-aligned title: actions take the leading spot, title follows.
      return AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(
          children: [
            ...actions,
            const SizedBox(width: 8),
            if (bar.title != null) Flexible(child: bar.title!),
          ],
        ),
      );
    }

    // Centered title: mirror the toolbar so the actions slot lands at the
    // start, and restore the real direction inside each slot.
    final direction = Directionality.of(context);
    Widget restore(Widget child) =>
        Directionality(textDirection: direction, child: child);
    final appBar = AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: bar.title == null ? null : restore(bar.title!),
      // Mirrored row: reverse so the actions keep their reading order.
      actions: [...actions.reversed.map(restore), const SizedBox(width: 8)],
    );
    return PreferredSize(
      preferredSize: appBar.preferredSize,
      child: Directionality(
        textDirection: direction == TextDirection.ltr
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: appBar,
      ),
    );
  }

  /// Actions fill the top and anchor to the bottom, with the rail below them.
  static Widget sideColumn(
    BuildContext context,
    Widget actions,
    Widget? tabs,
    bool hasActions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Expanded(child: actions),
          if (tabs != null) ...[const SizedBox(height: 12), tabs],
        ],
      ),
    );
  }

  /// Chips grow from the bottom while fading and scaling in.
  static Widget actionTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    // Height grows from the bottom, so the chips above glide into place.
    return ClipRect(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Align(
          alignment: Alignment.bottomCenter,
          heightFactor: animation.value.clamp(0.0, 1.0),
          child: child,
        ),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: child,
          ),
        ),
      ),
    );
  }
}
