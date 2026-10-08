import 'package:flutter/widgets.dart';

import 'dock_icon.dart';

/// Builds a widget for a [DockIcon], in a design system's own way.
typedef DockIconWidgetBuilder =
    Widget Function(BuildContext context, DockIcon icon);

/// Shows [icon] with [builder] and cross-fades when it changes, such as back
/// turning into close or a star into a filled star.
///
/// Icons are told apart by [DockIcon.identity], so rebuilding the same icon
/// doesn't restart the animation; give custom widget icons an identity
/// (`DockIcon.widget(w, identity: ...)`). With reduced motion
/// (`MediaQuery.disableAnimations`) it swaps without animating.
///
/// Action builders use it with their own icon rendering:
///
/// ```dart
/// action: (context, action, placement) => MyIconButton(
///   icon: DockIconMorph(icon: action.icon!, builder: (context, icon) => MyIcon.of(icon)),
///   onPressed: action.onPressed,
/// ),
/// ```
///
/// `DockMaterial.morphingIcon` is this with Material icons.
class DockIconMorph extends StatelessWidget {
  /// Shows [icon] with [builder], cross-fading when it changes.
  const DockIconMorph({
    super.key,
    required this.icon,
    required this.builder,
    this.duration = const Duration(milliseconds: 200),
  });

  /// The icon to show.
  final DockIcon icon;

  /// Builds the widget for an icon.
  final DockIconWidgetBuilder builder;

  /// How long the cross-fade takes.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(
        key: ValueKey<Object>(icon.identity),
        child: Builder(builder: (context) => builder(context, icon)),
      ),
    );
  }
}
