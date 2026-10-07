import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../geometry/body_mode.dart';
import '../geometry/dock_geometry.dart';
import '../geometry/layout_mode.dart';
import '../geometry/side.dart';

/// The frame's children.
enum DockFrameSlot {
  /// The page subtree. Always present, so a mode switch never remounts it.
  body,

  /// The tab bar (compact mode only).
  bar,

  /// The side column (wide mode only).
  column,
}

/// Box constraints for the frame's body that also carry the frame's
/// [geometry], which is only known after the bar has been measured.
///
/// The body scope reads them during layout and publishes the geometry.
class DockFrameConstraints extends BoxConstraints {
  /// Tight constraints of [size] that carry [geometry].
  DockFrameConstraints.tight(super.size, {required this.geometry})
    : super.tight();

  /// The frame's geometry for this layout.
  final DockGeometry geometry;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is DockFrameConstraints &&
      other.geometry == geometry;

  @override
  int get hashCode => Object.hash(super.hashCode, geometry);
}

/// Lays out a frame: the bar or the column first, then the body in the free
/// area ([DockBodyMode.inset]) or across the whole frame
/// ([DockBodyMode.overlay]).
class DockFrameLayout
    extends SlottedMultiChildRenderObjectWidget<DockFrameSlot, RenderBox> {
  /// Lays out [body] with [bar] (compact) or [column] (wide).
  const DockFrameLayout({
    super.key,
    required this.mode,
    required this.side,
    required this.columnOnRight,
    required this.columnWidth,
    required this.bodyMode,
    required this.systemPadding,
    required this.body,
    this.bar,
    this.column,
  });

  /// The layout mode; the column is only laid out in wide mode.
  final DockLayoutMode mode;

  /// The column's logical edge, for the published geometry.
  final DockSide side;

  /// Whether the column is on the physical right edge.
  final bool columnOnRight;

  /// The column's width, not counting the system inset on its edge.
  final double columnWidth;

  /// Whether the body is laid out beside the chrome or under it.
  final DockBodyMode bodyMode;

  /// The `MediaQuery.padding` above the frame.
  final EdgeInsets systemPadding;

  /// The page subtree.
  final Widget body;

  /// The tab bar, compact mode.
  final Widget? bar;

  /// The side column, wide mode.
  final Widget? column;

  @override
  Iterable<DockFrameSlot> get slots => DockFrameSlot.values;

  @override
  Widget? childForSlot(DockFrameSlot slot) => switch (slot) {
    DockFrameSlot.body => body,
    DockFrameSlot.bar => mode == DockLayoutMode.compact ? bar : null,
    DockFrameSlot.column => mode == DockLayoutMode.wide ? column : null,
  };

  @override
  RenderDockFrame createRenderObject(BuildContext context) => RenderDockFrame(
    mode: mode,
    side: side,
    columnOnRight: columnOnRight,
    columnWidth: columnWidth,
    bodyMode: bodyMode,
    systemPadding: systemPadding,
  );

  @override
  void updateRenderObject(BuildContext context, RenderDockFrame renderObject) {
    renderObject
      ..mode = mode
      ..side = side
      ..columnOnRight = columnOnRight
      ..columnWidth = columnWidth
      ..bodyMode = bodyMode
      ..systemPadding = systemPadding;
  }
}

/// The render object of [DockFrameLayout].
class RenderDockFrame extends RenderBox
    with SlottedContainerRenderObjectMixin<DockFrameSlot, RenderBox> {
  /// Creates the frame's render object.
  RenderDockFrame({
    required DockLayoutMode mode,
    required DockSide side,
    required bool columnOnRight,
    required double columnWidth,
    required DockBodyMode bodyMode,
    required EdgeInsets systemPadding,
  }) : _mode = mode,
       _side = side,
       _columnOnRight = columnOnRight,
       _columnWidth = columnWidth,
       _bodyMode = bodyMode,
       _systemPadding = systemPadding;

  /// See [DockFrameLayout.mode].
  DockLayoutMode get mode => _mode;
  DockLayoutMode _mode;
  set mode(DockLayoutMode value) {
    if (value == _mode) return;
    _mode = value;
    markNeedsLayout();
  }

  /// See [DockFrameLayout.side].
  DockSide get side => _side;
  DockSide _side;
  set side(DockSide value) {
    if (value == _side) return;
    _side = value;
    markNeedsLayout();
  }

  /// See [DockFrameLayout.columnOnRight].
  bool get columnOnRight => _columnOnRight;
  bool _columnOnRight;
  set columnOnRight(bool value) {
    if (value == _columnOnRight) return;
    _columnOnRight = value;
    markNeedsLayout();
  }

  /// See [DockFrameLayout.columnWidth].
  double get columnWidth => _columnWidth;
  double _columnWidth;
  set columnWidth(double value) {
    if (value == _columnWidth) return;
    _columnWidth = value;
    markNeedsLayout();
  }

  /// See [DockFrameLayout.bodyMode].
  DockBodyMode get bodyMode => _bodyMode;
  DockBodyMode _bodyMode;
  set bodyMode(DockBodyMode value) {
    if (value == _bodyMode) return;
    _bodyMode = value;
    markNeedsLayout();
  }

  /// See [DockFrameLayout.systemPadding].
  EdgeInsets get systemPadding => _systemPadding;
  EdgeInsets _systemPadding;
  set systemPadding(EdgeInsets value) {
    if (value == _systemPadding) return;
    _systemPadding = value;
    markNeedsLayout();
  }

  RenderBox? get _body => childForSlot(DockFrameSlot.body);
  RenderBox? get _bar => childForSlot(DockFrameSlot.bar);
  RenderBox? get _column => childForSlot(DockFrameSlot.column);

  /// Children in paint order: the body first, so the chrome is drawn over it.
  List<RenderBox> get _paintOrder => [?_body, ?_bar, ?_column];

  bool _reportedShortBar = false;

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth && constraints.hasBoundedHeight,
      'DockShell and DockModalScope fill the space they get, so they need '
      'bounded constraints. Got $constraints.',
    );
    size = constraints.biggest;

    var chrome = EdgeInsets.zero;
    final column = _column;
    final bar = _bar;
    if (column != null) {
      final inset = _columnOnRight ? _systemPadding.right : _systemPadding.left;
      final width = inset + _columnWidth;
      column.layout(BoxConstraints.tightFor(width: width, height: size.height));
      _offset(column, Offset(_columnOnRight ? size.width - width : 0, 0));
      chrome = _columnOnRight
          ? EdgeInsets.only(right: width)
          : EdgeInsets.only(left: width);
    } else if (bar != null) {
      bar.layout(
        BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          maxHeight: size.height,
        ),
        parentUsesSize: true,
      );
      final height = bar.size.height;
      _offset(bar, Offset(0, size.height - height));
      chrome = EdgeInsets.only(bottom: height);
      assert(() {
        if (!_reportedShortBar &&
            height > 0 &&
            height < _systemPadding.bottom - precisionErrorTolerance) {
          _reportedShortBar = true;
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: FlutterError.fromParts([
                ErrorSummary(
                  'The tab bar is shorter than the bottom safe area.',
                ),
                ErrorDescription(
                  'The bar is ${height.toStringAsFixed(1)} high, and the '
                  'system reserves ${_systemPadding.bottom.toStringAsFixed(1)} '
                  'at the bottom (home indicator), so the bar draws under it.',
                ),
                ErrorHint(
                  'The tab bar builder owns the bottom safe area: include '
                  'MediaQuery.paddingOf(context).bottom in its height, for '
                  'example with SafeArea(top: false, child: ...).',
                ),
              ]),
              library: 'nav_dock',
            ),
          );
        }
        return true;
      }());
    }

    final geometry = DockGeometry(
      mode: _mode,
      side: _side,
      columnOnRight: _columnOnRight,
      bodyMode: _bodyMode,
      systemPadding: _systemPadding,
      chrome: chrome,
    );
    final body = _body;
    if (body != null) {
      final rect = geometry.strip.deflateRect(Offset.zero & size);
      body.layout(DockFrameConstraints.tight(rect.size, geometry: geometry));
      _offset(body, rect.topLeft);
    }
  }

  static void _offset(RenderBox child, Offset offset) =>
      (child.parentData! as BoxParentData).offset = offset;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _paintOrder) {
      context.paintChild(
        child,
        (child.parentData! as BoxParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in _paintOrder.reversed) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<DockLayoutMode>('mode', _mode))
      ..add(EnumProperty<DockBodyMode>('bodyMode', _bodyMode))
      ..add(
        FlagProperty(
          'columnOnRight',
          value: _columnOnRight,
          ifTrue: 'column on right',
        ),
      )
      ..add(DoubleProperty('columnWidth', _columnWidth))
      ..add(DiagnosticsProperty<EdgeInsets>('systemPadding', _systemPadding));
  }
}
