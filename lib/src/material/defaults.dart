import 'package:flutter/material.dart';

import '../builders/builders.dart';
import '../config/navigation.dart';
import '../frame/side_column_layout.dart';
import '../tabs/tab_item.dart';
import '../models/action.dart';
import '../models/dock_badge.dart';
import '../models/dock_icon.dart';
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
/// [T] and [A] are the tabs' and actions' payload types; the defaults work for
/// any, so a typed app can use `DockMaterialBuilders<MyTab, MyAction>()` as a
/// base for typed overrides.
class DockMaterialBuilders<T, A> extends DockBuilders<T, A> {
  /// The Material defaults.
  const DockMaterialBuilders()
    : super(
        tabItem: DockMaterial.tabItem,
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

  /// A tab: a [NavigationDestination] in the tab bar, a selectable
  /// [IconButton] in the rail. Badges are Material [Badge]s.
  static Widget tabItem(BuildContext context, DockTabItemData<Object?> data) {
    final tab = data.tab;
    Widget icon(bool selected) =>
        badge(DockMaterial.icon(tab.iconFor(selected: selected)), tab.badge);
    if (data.placement == DockTabPlacement.bar) {
      return NavigationDestination(
        icon: icon(false),
        selectedIcon: icon(true),
        label: tab.label ?? '',
        tooltip: tab.tooltip,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final extent = DockNavigation.of(context).sideItemExtent - 2 * _railPadding;
    return IconButton(
      isSelected: data.selected,
      icon: icon(false),
      selectedIcon: icon(true),
      tooltip: tab.tooltip ?? tab.label,
      onPressed: data.onTap,
      style: IconButton.styleFrom(
        fixedSize: Size.square(extent),
        backgroundColor: data.selected
            ? scheme.secondaryContainer
            : Colors.transparent,
        foregroundColor: data.selected
            ? scheme.onSecondaryContainer
            : scheme.onSurfaceVariant,
      ),
    );
  }

  /// [icon] with a Material [Badge] for [badge]; [icon] itself without one.
  static Widget badge(Widget icon, DockBadge? badge) {
    if (badge == null) return icon;
    final label = badge.label;
    return Badge(label: label == null ? null : Text(label), child: icon);
  }

  /// A Material 3 [NavigationBar] of the items. It marks itself as a tab bar
  /// for assistive technology.
  static Widget tabBar(
    BuildContext context,
    DockTabsData<Object?> data,
    List<Widget> items,
  ) {
    return NavigationBar(
      selectedIndex: data.currentIndex,
      onDestinationSelected: data.onSelected,
      destinations: items,
    );
  }

  /// One vertical pill of the items, `sideItemExtent` wide, marked as a tab
  /// bar with [DockTabBarSemantics].
  static Widget rail(
    BuildContext context,
    DockTabsData<Object?> data,
    List<Widget> items,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      shape: const StadiumBorder(),
      child: DockTabBarSemantics(
        child: Padding(
          padding: const EdgeInsets.all(_railPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: item,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Round chip in the side column; icon or text button in the bar.
  ///
  /// [DockActionRole.primary] chips use the primary container color. A text
  /// action shows its label; an icon action uses it as tooltip.
  static Widget action(
    BuildContext context,
    DockAction<Object?> action,
    DockActionPlacement placement,
  ) {
    final l10n = MaterialLocalizations.of(context);
    final tooltip =
        action.tooltip ??
        action.label ??
        switch (action.role) {
          DockActionRole.back => l10n.backButtonTooltip,
          DockActionRole.close => l10n.closeButtonTooltip,
          _ => null,
        };
    final icon = action.icon;
    Widget semantic(Widget child) {
      final label = action.semanticLabel;
      return label == null ? child : Semantics(label: label, child: child);
    }

    if (icon == null) {
      return semantic(
        TextButton(
          onPressed: action.onPressed,
          child: badge(Text(action.label!), action.badge),
        ),
      );
    }
    final glyph = badge(morphingIcon(icon), action.badge);
    if (placement == DockActionPlacement.sideColumn) {
      final scheme = Theme.of(context).colorScheme;
      final primary = action.role == DockActionRole.primary;
      return semantic(
        Material(
          color: primary
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          elevation: 3,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            tooltip: tooltip,
            onPressed: action.onPressed,
            color: primary ? scheme.onPrimaryContainer : null,
            icon: glyph,
            style: IconButton.styleFrom(
              fixedSize: Size.square(DockNavigation.of(context).sideItemExtent),
            ),
          ),
        ),
      );
    }
    return semantic(
      IconButton(tooltip: tooltip, onPressed: action.onPressed, icon: glyph),
    );
  }

  /// [icon] as a Material widget: [DockIcon.back] is a [BackButtonIcon]
  /// (chevron or arrow by platform), [DockIcon.close] the close icon, the
  /// others their own widget.
  static Widget icon(DockIcon icon, {double? size, Color? color}) =>
      switch (icon) {
        DockPlatformIcon(kind: DockPlatformIconKind.back) =>
          const BackButtonIcon(),
        DockPlatformIcon(kind: DockPlatformIconKind.close) => Icon(
          Icons.close,
          size: size,
          color: color,
        ),
        _ => icon.toWidget(size: size, color: color),
      };

  /// [icon] that cross-fades when it changes (back → close, star → filled
  /// star). Icons are told apart by [DockIcon.identity], so rebuilding the
  /// same icon doesn't restart the animation; give custom widget icons an
  /// identity (`DockIcon.widget(w, identity: ...)`) or a key.
  static Widget morphingIcon(DockIcon icon) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey<Object>(icon.identity),
        child: DockMaterial.icon(icon),
      ),
    );
  }

  /// Scaffold + AppBar. When the side column is at the start edge, the bar's
  /// actions move to the start too, so everything sits on one side.
  static Widget page(
    BuildContext context,
    DockBarData<Object?> bar,
    Widget body,
  ) {
    if (bar.trailingAtStart && bar.trailing.isNotEmpty && bar.leading == null) {
      return Scaffold(appBar: _actionsAtStartAppBar(context, bar), body: body);
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // A text leading action ("Cancel") needs more than the icon width.
        leadingWidth: bar.leading?.icon == null && bar.leading != null
            ? 96
            : null,
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

  // Only without a leading action in the bar (wide mode, leading in the
  // column).
  static PreferredSizeWidget _actionsAtStartAppBar(
    BuildContext context,
    DockBarData<Object?> bar,
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
  /// The rail gets its height first ([DockSideColumnLayout]).
  static Widget sideColumn(
    BuildContext context,
    Widget actions,
    Widget? tabs,
    bool hasActions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DockSideColumnLayout(actions: actions, rail: tabs),
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
