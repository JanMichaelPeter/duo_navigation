import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../geometry/dock_geometry.dart';

/// Lets [child] run under the side column and the tab bar while the body is
/// laid out beside them (`DockBodyMode.inset`): a hero image, a carousel, a
/// map, a gradient behind one section.
///
/// The child is laid out widened by the strip toward the chrome, while this
/// widget keeps its own size, so siblings are not affected. It assumes its box
/// touches the body's edge on that side: use it for full-width (or, toward the
/// bar, full-height) content, and turn an edge off with [column] or [bar].
///
/// Inside the child, `MediaQuery.padding` on the covered edges equals the
/// strip, so `SafeArea` and list padding keep content clear of the chrome;
/// [DockInset] does the same for single children.
///
/// It is a no-op where there is no strip: outside a frame, in
/// `DockBodyMode.overlay`, while the navigation is hidden, and inside another
/// [DockBleed]. The widget tree is the same in every case, so the child keeps
/// its state across mode changes.
///
/// Taps in the strip go to the chrome, not to the child: put interactive
/// content in a [DockInset].
///
/// Ancestors that clip cut a bleed at the body's edge: `ClipRect` and other
/// clips, scroll views (wrap the scroll view, not an item in it), and a
/// `Navigator` (give it `clipBehavior: Clip.none`). `Stack`, `IndexedStack` and
/// `DockTabStack` don't. A debug message names the first clipping ancestor it
/// finds. For a background behind a whole page, `DockShell.backdrop` and
/// `DockPageScope.backdrop` are not affected by clips.
class DockBleed extends StatelessWidget {
  /// Widens [child] under the chrome.
  const DockBleed({
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

  /// The strip beside the body at [context]: how far a [DockBleed] there
  /// would widen, per edge. Zero outside a frame, in overlay mode, while the
  /// navigation is hidden, and inside a bleed.
  static EdgeInsets insetOf(BuildContext context) {
    if (_BleedScope.maybeOf(context) != null) return EdgeInsets.zero;
    return DockGeometry.maybeOf(
          context,
          aspect: DockGeometryAspect.chrome,
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
            padding: _max(mediaQuery.padding, extension),
            viewPadding: _max(mediaQuery.viewPadding, extension),
          ),
          child: child,
        ),
      ),
    );
  }

  static EdgeInsets _max(EdgeInsets a, EdgeInsets b) => EdgeInsets.fromLTRB(
    math.max(a.left, b.left),
    math.max(a.top, b.top),
    math.max(a.right, b.right),
    math.max(a.bottom, b.bottom),
  );
}

/// Keeps [child] beside the chrome inside a [DockBleed]: pads it by the strip
/// the bleed widened into, and removes that padding from `MediaQuery` again.
/// A no-op outside a bleed.
///
/// ```dart
/// DockBleed(
///   child: ListView(
///     children: DockInset.wrapAll([
///       DockBleedItem(child: Image.asset('hero.webp', fit: BoxFit.cover)),
///       const Text('Details'), // inset
///     ]),
///   ),
/// )
/// ```
class DockInset extends StatelessWidget {
  /// Insets [child] inside a bleed.
  const DockInset({super.key, required this.child});

  /// The content that stays beside the chrome.
  final Widget child;

  /// [children] with each wrapped in a [DockInset], except those wrapped in a
  /// [DockBleedItem], which keep bleeding. For the children of a scroll view
  /// inside a [DockBleed].
  static List<Widget> wrapAll(List<Widget> children) => [
    for (final child in children)
      child is DockBleedItem ? child : DockInset(child: child),
  ];

  @override
  Widget build(BuildContext context) {
    final extension = _BleedScope.maybeOf(context);
    if (extension == null || extension == EdgeInsets.zero) return child;
    final mediaQuery = MediaQuery.of(context);
    EdgeInsets without(EdgeInsets padding) => EdgeInsets.fromLTRB(
      extension.left > 0 ? 0 : padding.left,
      padding.top,
      extension.right > 0 ? 0 : padding.right,
      extension.bottom > 0 ? 0 : padding.bottom,
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

/// Marks a child of [DockInset.wrapAll] that keeps bleeding.
class DockBleedItem extends StatelessWidget {
  /// Lets [child] bleed in a [DockInset.wrapAll] list.
  const DockBleedItem({super.key, required this.child});

  /// The content that bleeds.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// The extension of the nearest [DockBleed], for [DockInset] and nested
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
  RenderDockBleed createRenderObject(BuildContext context) =>
      RenderDockBleed(extension: extension);

  @override
  void updateRenderObject(BuildContext context, RenderDockBleed renderObject) {
    renderObject.extension = extension;
  }
}

/// Lays its child out widened by [extension] and keeps its own size, so the
/// child overflows toward the chrome. Adds no layer.
class RenderDockBleed extends RenderShiftedBox {
  /// Widens the child by [extension].
  RenderDockBleed({required EdgeInsets extension, RenderBox? child})
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
      final name = node.runtimeType.toString();
      if (name == 'RenderDockFrame') return;
      final clips =
          node is RenderClipRect ||
          node is RenderClipRRect ||
          node is RenderClipOval ||
          node is RenderClipPath ||
          (node is RenderViewportBase && node.clipBehavior != Clip.none) ||
          // A Navigator's Overlay clips unless its clipBehavior is none.
          name == '_RenderTheater';
      if (clips) {
        _reportedClip = true;
        debugPrint(
          'nav_dock: a DockBleed is clipped by an ancestor ($name), so it '
          'stops at the body\'s edge. Wrap the scroll view instead of an item '
          'in it, give a Navigator clipBehavior: Clip.none, or use a backdrop '
          '(DockShell.backdrop, DockPageScope.backdrop) for backgrounds.',
        );
        return;
      }
      node = node.parent;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('extension', _extension));
  }
}
