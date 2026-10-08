import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bar_data.dart';
import '../models/enums.dart';
import '../page/bar_layout.dart';

/// A Material [AppBar] for the page around it: it reads the page's
/// `DockBarData` (from a `DockPageScope` or `DockPage`) and lays out its
/// leading action, title and actions with [DockBarLayout].
///
/// Use it in a page's own `Scaffold`:
///
/// ```dart
/// DockPageScope(
///   title: const Text('Details'),
///   child: Scaffold(appBar: const DockAppBar(), body: ...),
/// )
/// ```
///
/// Colors, elevation and text styles come from the [AppBarTheme] unless set
/// here; the parameters are [AppBar]'s. When the side column is at the start
/// edge, the bar's actions move to the start too.
class DockAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// An app bar for the page around it.
  const DockAppBar({
    super.key,
    this.centerTitle,
    this.toolbarHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.shape,
    this.systemOverlayStyle,
    this.titleTextStyle,
    this.flexibleSpace,
    this.bottom,
  });

  /// Whether the title is centered. Null: the [AppBarTheme], else centered on
  /// iOS and macOS.
  final bool? centerTitle;

  /// The toolbar height. Null: the [AppBarTheme], else [kToolbarHeight].
  final double? toolbarHeight;

  /// The background color. Null: the [AppBarTheme].
  final Color? backgroundColor;

  /// The color of the title and the action icons. Null: the [AppBarTheme].
  final Color? foregroundColor;

  /// See [AppBar.elevation].
  final double? elevation;

  /// See [AppBar.scrolledUnderElevation].
  final double? scrolledUnderElevation;

  /// See [AppBar.shape].
  final ShapeBorder? shape;

  /// See [AppBar.systemOverlayStyle].
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// The title's text style. Null: the [AppBarTheme].
  final TextStyle? titleTextStyle;

  /// A widget behind the toolbar, such as an image; see
  /// [AppBar.flexibleSpace].
  final Widget? flexibleSpace;

  /// A widget below the toolbar, such as a `TabBar`.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final bar = DockBarData.of<Object?, Object?>(context);
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final centered =
        centerTitle ??
        appBarTheme.centerTitle ??
        switch (theme.platform) {
          TargetPlatform.iOS || TargetPlatform.macOS => true,
          _ => false,
        };
    final leading = bar.leading;
    return AppBar(
      automaticallyImplyLeading: false,
      // The whole toolbar is one DockBarLayout in the title slot.
      titleSpacing: 0,
      centerTitle: false,
      toolbarHeight: toolbarHeight,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      shape: shape,
      systemOverlayStyle: systemOverlayStyle,
      titleTextStyle: titleTextStyle,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      title: IconTheme.merge(
        data: foregroundColor != null
            ? IconThemeData(color: foregroundColor)
            : appBarTheme.actionsIconTheme ??
                  IconThemeData(
                    color:
                        appBarTheme.foregroundColor ??
                        theme.colorScheme.onSurfaceVariant,
                  ),
        // The title slot leaves the height open; the layout fills the bar.
        child: SizedBox(
          width: double.infinity,
          height: toolbarHeight ?? appBarTheme.toolbarHeight ?? kToolbarHeight,
          child: DockBarLayout(
            leading: leading == null
                ? null
                : bar.buildAction(leading, DockActionPlacement.barLeading),
            title: bar.title,
            trailing: [
              for (final action in bar.trailing)
                bar.buildAction(action, DockActionPlacement.barTrailing),
            ],
            centerTitle: centered,
            actionsAtStart: bar.trailingAtStart,
            leadingAtEnd: bar.leadingAtEnd,
          ),
        ),
      ),
    );
  }
}
