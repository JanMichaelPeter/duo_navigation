import 'package:nav_dock/nav_dock.dart';
import 'package:flutter/material.dart';

/// Put on [DockAction.data] to highlight a chip. The package passes
/// `data` through untouched; only builders that look for it react.
enum ActionRole { primary }

/// A complete custom look, built only from the public builder hooks.
///
/// Optional: without it (plain `DockNavigationData()`) nav_dock uses
/// the Material defaults in `DockDefaults`. Override as many or as few
/// builders as you like; everything not set keeps its default.
///
/// Showcases, one hook each:
/// * [tabBar]: floating capsule instead of a NavigationBar.
/// * [rail]: rounded rectangle with an animated selection.
/// * [action]: square chips in the column; bar actions keep the defaults.
/// * [page]: wraps [DockDefaults.page] with a theme override.
/// * [sideColumn]: rail separated from the actions by a short divider.
/// * [actionTransition]: chips slide up and fade instead of scaling.
/// * `DockTab.data` (an int) shows as a badge in bar and rail.
abstract final class CustomStyle {
  static const double _radius = 32;
  static const double _railPadding = 4;

  static DockNavigationData data(DockNavigationData base) {
    return base.copyWith(
      tabBarBuilder: tabBar,
      railBuilder: rail,
      actionBuilder: action,
      pageBuilder: page,
      sideColumnBuilder: sideColumn,
      actionTransitionBuilder: actionTransition,
      sideColumnWidth: 80,
      sideItemExtent: 60, // rail and chips both read this
      actionSpacing: 12,
      actionAnimationDuration: const Duration(milliseconds: 350),
      actionAnimationCurve: Curves.easeOutQuart,
    );
  }

  // ------------------------------------------------------------- tab bar ---

  static Widget tabBar(BuildContext context, DockTabsData data) {
    final scheme = Theme.of(context).colorScheme;
    // The frame reports the bar's full height (margin included) to the body,
    // so lists end above the capsule while full-bleed content shows around it.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: scheme.inverseSurface,
        shape: const StadiumBorder(),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var i = 0; i < data.tabs.length; i++)
                Expanded(
                    child: _TabItem(data: data, index: i, showLabel: true)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- rail ---

  static Widget rail(BuildContext context, DockTabsData data) {
    final scheme = Theme.of(context).colorScheme;
    final extent = DockNavigation.of(context).sideItemExtent;
    return Material(
      color: scheme.inverseSurface,
      borderRadius: BorderRadius.circular(_radius),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(_railPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < data.tabs.length; i++)
              SizedBox.square(
                dimension: extent - 2 * _railPadding,
                child: _TabItem(data: data, index: i, showLabel: false),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- actions ---

  static Widget action(
      BuildContext context, DockAction action, DockActionPlacement placement) {
    // Title bar actions: reuse the default look.
    if (placement != DockActionPlacement.sideColumn) {
      return DockDefaults.action(context, action, placement);
    }
    final scheme = Theme.of(context).colorScheme;
    final extent = DockNavigation.of(context).sideItemExtent;
    final primary = action.data == ActionRole.primary;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
    return Material(
      color: primary ? scheme.primary : scheme.inverseSurface,
      shape: shape,
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: action.tooltip ?? action.label,
        // Already guarded by the package (active page, no transition,
        // cooldown); just call it.
        onPressed: action.onPressed,
        color: primary ? scheme.onPrimary : scheme.onInverseSurface,
        style: IconButton.styleFrom(
          fixedSize: Size.square(extent),
          shape: shape,
        ),
        icon: DockDefaults.morphingIcon(action.icon!),
      ),
    );
  }

  // ---------------------------------------------------------------- page ---

  /// Wrapping a default instead of rewriting it: same Scaffold + AppBar,
  /// different app bar theme.
  static Widget page(BuildContext context, DockBarData bar, Widget body) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        appBarTheme: AppBarTheme(
          centerTitle: false,
          scrolledUnderElevation: 0,
          backgroundColor: theme.colorScheme.surface,
          titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      child: DockDefaults.page(context, bar, body),
    );
  }

  // --------------------------------------------------------- side column ---

  /// The divider only separates chips from the rail, so it fades out with
  /// the chips when the page has none.
  static Widget sideColumn(
    BuildContext context,
    Widget actions,
    Widget? tabs,
    bool hasActions,
  ) {
    final config = DockNavigation.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Expanded(child: actions),
          if (tabs != null) ...[
            AnimatedOpacity(
              opacity: hasActions ? 1 : 0,
              duration: config.actionAnimationDuration,
              curve: config.actionAnimationCurve,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: SizedBox(width: 24, child: Divider(height: 1)),
              ),
            ),
            tabs,
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------- transition ---

  /// Height grows from the bottom (so chips above glide instead of jumping)
  /// while the chip slides up and fades in.
  static Widget actionTransition(
      BuildContext context, Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      builder: (context, child) => Align(
        alignment: Alignment.bottomCenter,
        heightFactor: animation.value.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }
}

/// One tab in the capsule bar or the rail.
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.data,
    required this.index,
    required this.showLabel,
  });

  final DockTabsData data;
  final int index;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tab = data.tabs[index];
    final selected = index == data.currentIndex;
    final foreground =
        selected ? scheme.onPrimaryContainer : scheme.onInverseSurface;
    final badge = tab.data is int ? tab.data! as int : 0;

    Widget icon = Badge.count(
      count: badge,
      isLabelVisible: badge > 0,
      child: selected ? tab.selectedIcon ?? tab.icon : tab.icon,
    );
    if (showLabel && tab.label != null) {
      icon = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 2),
          Text(tab.label!,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: foreground)),
        ],
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: Tooltip(
        message: tab.tooltip ?? tab.label ?? '',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => data.onSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(32),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: Center(heightFactor: 1, child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
