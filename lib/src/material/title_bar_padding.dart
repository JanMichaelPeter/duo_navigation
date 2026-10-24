import 'package:flutter/material.dart';

import '../config/navigation.dart';

/// Moves the title bar of a page's own [Scaffold] up to the window's top
/// edge, beside the status icons, like the default page does.
///
/// A [Scaffold] sizes its app bar from its top padding, so a [DuoAppBar]
/// can't move itself into the top safe-area band (an unfolded iPhone Duo in
/// portrait). Wrap the [Scaffold] in this widget: it gives it the top from
/// [DuoNavigation.titleBarPaddingOf], and the [DuoAppBar] ends its title and
/// actions before the icons.
///
/// ```dart
/// DuoPageScope(
///   title: const Text('Profile'),
///   child: DuoTitleBarPadding(
///     child: Scaffold(appBar: const DuoAppBar(), body: ...),
///   ),
/// )
/// ```
///
/// Use it only around a [Scaffold] with an app bar: the [Scaffold] keeps its
/// body below the bar, while other content would move up under the icons.
/// Without a `DuoNavigationData.barRegionSource`, or where it has no answer,
/// it changes nothing.
class DuoTitleBarPadding extends StatelessWidget {
  /// Gives [child] the title bar's top padding.
  const DuoTitleBarPadding({
    super.key,
    this.toolbarHeight,
    required this.child,
  });

  /// The height of the app bar's toolbar, as passed to [DuoAppBar]. Null: the
  /// [AppBarTheme], else [kToolbarHeight].
  final double? toolbarHeight;

  /// The [Scaffold] with the app bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height =
        toolbarHeight ??
        Theme.of(context).appBarTheme.toolbarHeight ??
        kToolbarHeight;
    final titleBar = DuoNavigation.titleBarPaddingOf(context, height);
    if (titleBar == null) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(padding: media.padding.copyWith(top: titleBar.top)),
      child: child,
    );
  }
}
