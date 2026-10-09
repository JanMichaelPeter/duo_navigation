import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../geometry/dock_geometry.dart';

/// Lets [child] run under the side column and the tab bar while the body is
/// laid out beside them (`DuoBodyMode.inset`): a hero image, a carousel, a
/// map, a gradient behind one section.
///
/// The child is laid out widened by the strip toward the chrome, while this
/// widget keeps its own size, so siblings are not affected. It assumes its box
/// touches the body's edge on that side: use it for full-width (or, toward the
/// bar, full-height) content, and turn an edge off with [column] or [bar].
///
/// Inside the child, `MediaQuery.padding` on the covered edges grows by the
/// strip (plus any system inset the body still had there, such as the part
/// of a cutout wider than the column), so `SafeArea` and list padding keep
/// content clear of the chrome;
/// [DuoInset] does the same for single children.
///
/// It is a no-op where there is no strip: outside a frame, in
/// `DuoBodyMode.overlay`, while the navigation is hidden, and inside another
/// [DuoBleed]. The widget tree is the same in every case, so the child keeps
/// its state across mode changes.
///
/// Taps in the strip go to the chrome, not to the child: put interactive
/// content in a [DuoInset].
///
/// Ancestors that clip cut a bleed at the body's edge: `ClipRect` and other
/// clips, scroll views (wrap the scroll view, not an item in it), and a
/// `Navigator` (give it `clipBehavior: Clip.none`). `Stack`, `IndexedStack` and
/// `DuoTabStack` don't. A debug message names the first clipping ancestor it
/// finds. For a background behind a whole page, `DuoShell.backdrop` and
/// `DuoPageScope.backdrop` are not affected by clips.
class DuoBleed extends StatelessWidget {
  /// Widens [child] under the chrome.
  const DuoBleed({
    super.key,
    this.column = true,
    this.bar = true,
    required this.child,
  });

  /// Whether to run under the side column (wide mode).
  final bool column;

  /// Whether to run under the tab bar (compact mode).
  final bool bar;

  /// The content that bleeds.
  final Widget child;

  /// The strip beside the body at [context]: how far a [DuoBleed] there
  /// would widen, per edge. Zero outside a frame, in overlay mode, while the
  /// navigation is hidden, and inside a bleed.
  static EdgeInsets insetOf(BuildContext context) {
    if (_BleedScope.maybeOf(context) != null) return EdgeInsets.zero;
    return DuoGeometry.maybeOf(
          context,
          aspect: DuoGeometryAspect.chrome,
        )?.strip ??
        EdgeInsets.zero;
  }

  @override
  Widget build(BuildContext context) {
    final strip = insetOf(context);
    final extension = EdgeInsets.only(
      left: column ? strip.left : 0,
      right: column ? strip.right : 0,
      bottom: bar ? strip.bottom : 0,
    );
    final mediaQuery = MediaQuery.of(context);
    return _RenderBleedWidget(
      extension: extension,
      child: _BleedScope(
        extension: extension,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            // The child starts the strip further out, so whatever inset the
            // body still had on that edge comes on top of it.
            padding: mediaQuery.padding + extension,
            viewPadding: mediaQuery.viewPadding + extension,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Keeps [child] beside the chrome inside a [DuoBleed]: pads it by the strip
/// the bleed widened into, and takes that padding out of `MediaQuery` again,
/// so the child sees what the body sees.
/// A no-op outside a bleed.
///
/// ```dart
/// DuoBleed(
///   child: ListView(
///     children: DuoInset.wrapAll([
///       DuoBleedItem(child: Image.asset('hero.webp', fit: BoxFit.cover)),
///       const Text('Details'), // inset
///     ]),
///   ),
/// )
/// ```
class DuoInset extends StatelessWidget {
  /// Insets [child] inside a bleed.
  const DuoInset({super.key, required this.child});

  /// The content that stays beside the chrome.
  final Widget child;

  /// [children] with each wrapped in a [DuoInset], except those wrapped in a
  /// [DuoBleedItem], which keep bleeding. For the children of a scroll view
  /// inside a [DuoBleed].
  static List<Widget> wrapAll(List<Widget> children) => [
    for (final child in children)
      child is DuoBleedItem ? child : DuoInset(child: child),
  ];

  @override
  Widget build(BuildContext context) {
    final extension = _BleedScope.maybeOf(context);
    if (extension == null || extension == EdgeInsets.zero) return child;
    final mediaQuery = MediaQuery.of(context);
    EdgeInsets without(EdgeInsets padding) => EdgeInsets.fromLTRB(
      math.max(0.0, padding.left - extension.left),
      padding.top,
      math.max(0.0, padding.right - extension.right),
      math.max(0.0, padding.bottom - extension.bottom),
    );
    return Padding(
      padding: extension,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          padding: without(mediaQuery.padding),
          viewPadding: without(mediaQuery.viewPadding),
        ),
        child: child,
      ),
    );
  }
}

/// Marks a child of [DuoInset.wrapAll] that keeps bleeding.
class DuoBleedItem extends StatelessWidget {
  /// Lets [child] bleed in a [DuoInset.wrapAll] list.
  const DuoBleedItem({super.key, required this.child});

  /// The content that bleeds.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// The extension of the nearest [DuoBleed], for [DuoInset] and nested
/// bleeds.
class _BleedScope extends InheritedWidget {
  const _BleedScope({required this.extension, required super.child});

  final EdgeInsets extension;

  static EdgeInsets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BleedScope>()?.extension;

  @override
  bool updateShouldNotify(_BleedScope oldWidget) =>
      extension != oldWidget.extension;
}

class _RenderBleedWidget extends SingleChildRenderObjectWidget {
  const _RenderBleedWidget({required this.extension, required super.child});

  final EdgeInsets extension;

  @override
  RenderDuoBleed createRenderObject(BuildContext context) =>
      RenderDuoBleed(extension: extension);

  @override
  void updateRenderObject(BuildContext context, RenderDuoBleed renderObject) {
    renderObject.extension = extension;
  }
}

/// Lays its child out widened by [extension] and keeps its own size, so the
/// child overflows toward the chrome. Adds no layer.
class RenderDuoBleed extends RenderShiftedBox {
  /// Widens the child by [extension].
  RenderDuoBleed({required EdgeInsets extension, RenderBox? child})
    : _extension = extension,
      super(child);

  /// How far the child extends past this box, per edge.
  EdgeInsets get extension => _extension;
  EdgeInsets _extension;
  set extension(EdgeInsets value) {
    if (value == _extension) return;
    _extension = value;
    markNeedsLayout();
  }

  BoxConstraints _widen(BoxConstraints constraints) {
    final dx = _extension.horizontal, dy = _extension.vertical;
    return BoxConstraints(
      minWidth: constraints.hasTightWidth
          ? constraints.minWidth + dx
          : constraints.minWidth,
      maxWidth: constraints.maxWidth + dx,
      minHeight: constraints.hasTightHeight
          ? constraints.minHeight + dy
          : constraints.minHeight,
      maxHeight: constraints.maxHeight + dy,
    );
  }

  Size _ownSize(BoxConstraints constraints, Size childSize) =>
      constraints.constrain(
        Size(
          math.max(0.0, childSize.width - _extension.horizontal),
          math.max(0.0, childSize.height - _extension.vertical),
        ),
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _ownSize(constraints, child.getDryLayout(_widen(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_widen(constraints), parentUsesSize: true);
    size = _ownSize(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      -_extension.left,
      -_extension.top,
    );
    assert(() {
      _debugCheckClips();
      return true;
    }());
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    0.0,
    (child?.getMinIntrinsicWidth(height + _extension.vertical) ?? 0) -
        _extension.horizontal,
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    0.0,
    (child?.getMaxIntrinsicWidth(height + _extension.vertical) ?? 0) -
        _extension.horizontal,
  );

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    0.0,
    (child?.getMinIntrinsicHeight(width + _extension.horizontal) ?? 0) -
        _extension.vertical,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    0.0,
    (child?.getMaxIntrinsicHeight(width + _extension.horizontal) ?? 0) -
        _extension.vertical,
  );

  bool _reportedClip = false;

  /// Names the first ancestor between this bleed and the frame that clips
  /// it, once.
  void _debugCheckClips() {
    if (_reportedClip || _extension == EdgeInsets.zero) return;
    var node = parent;
    while (node != null) {
      if (node.runtimeType.toString() == 'RenderDuoFrame') return;
      final cause = _clipCause(node);
      if (cause != null) {
        _reportedClip = true;
        debugPrint(
          'duo_navigation: a DuoBleed is clipped by $cause, so it stops at the '
          'body\'s edge. For backgrounds, a backdrop (DuoShell.backdrop, '
          'DuoPageScope.backdrop) is never clipped.',
        );
        return;
      }
      node = node.parent;
    }
  }

  /// What clips at [node], in words an adopter can act on, or null if
  /// nothing does. A clip set to [Clip.none] doesn't.
  static String? _clipCause(RenderObject node) {
    if (node is RenderViewportBase) {
      return node.clipBehavior == Clip.none
          ? null
          : 'a scroll view (put the DuoBleed around the scroll view, not '
                'around an item in it)';
    }
    final (clip, widget) = switch (node) {
      RenderClipRect() => (node.clipBehavior, 'ClipRect'),
      RenderClipRRect() => (node.clipBehavior, 'ClipRRect'),
      RenderClipOval() => (node.clipBehavior, 'ClipOval'),
      RenderClipPath() => (node.clipBehavior, 'ClipPath'),
      _ => (null, null),
    };
    if (clip != null) {
      return clip == Clip.none
          ? null
          : 'a $widget (pass clipBehavior: Clip.none, or move the DuoBleed '
                'above it)';
    }
    // A Navigator's Overlay; its render object is private.
    if (node.runtimeType.toString() == '_RenderTheater') {
      // ignore: avoid_dynamic_calls
      final theaterClip = (node as dynamic).clipBehavior as Clip;
      return theaterClip == Clip.none
          ? null
          : 'the Overlay of a Navigator (pass clipBehavior: Clip.none to the '
                'Navigator, or use DuoTabNavigator)';
    }
    return null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('extension', _extension));
  }
}
