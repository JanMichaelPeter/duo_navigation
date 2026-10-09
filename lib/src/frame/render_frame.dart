import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../config/column_inset.dart';

import '../geometry/body_mode.dart';
import '../geometry/dock_geometry.dart';
import '../geometry/layout_mode.dart';
import '../geometry/side.dart';

/// The frame's children.
enum DuoFrameSlot {
  /// Painted across the whole frame, under the body and the chrome.
  backdrop,

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
class DuoFrameConstraints extends BoxConstraints {
  /// Tight constraints of [size] that carry [geometry].
  DuoFrameConstraints.tight(super.size, {required this.geometry})
    : super.tight();

  /// The frame's geometry for this layout.
  final DuoGeometry geometry;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is DuoFrameConstraints &&
      other.geometry == geometry;

  @override
  int get hashCode => Object.hash(super.hashCode, geometry);
}

/// Lays out a frame: the bar or the column first, then the body in the free
/// area ([DuoBodyMode.inset]) or across the whole frame
/// ([DuoBodyMode.overlay]).
class DuoFrameLayout
    extends SlottedMultiChildRenderObjectWidget<DuoFrameSlot, RenderBox> {
  /// Lays out [body] with [bar] (compact) or [column] (wide).
  const DuoFrameLayout({
    super.key,
    required this.mode,
    required this.side,
    required this.columnOnRight,
    required this.columnWidth,
    this.columnInset = DuoColumnInset.overlap,
    required this.bodyMode,
    required this.systemPadding,
    required this.visibility,
    this.keyboard = 0,
    this.liftColumn = false,
    this.liftBar = false,
    this.liftBody = false,
    required this.body,
    this.backdrop,
    this.bar,
    this.column,
  });

  /// The layout mode; the column is only laid out in wide mode.
  final DuoLayoutMode mode;

  /// The column's logical edge, for the published geometry.
  final DuoSide side;

  /// Whether the column is on the physical right edge.
  final bool columnOnRight;

  /// The column's width, not counting the system inset on its edge.
  final double columnWidth;

  /// Whether the column sits over the system inset on its edge or after it.
  final DuoColumnInset columnInset;

  /// Whether the body is laid out beside the chrome or under it.
  final DuoBodyMode bodyMode;

  /// The `MediaQuery.padding` above the frame.
  final EdgeInsets systemPadding;

  /// How far the bar and column are shown, from 0 (hidden) to 1. The render
  /// object follows it on every tick without a rebuild.
  final Animation<double> visibility;

  /// The software keyboard's height (`MediaQuery.viewInsets.bottom` above the
  /// frame).
  final double keyboard;

  /// Whether the column is laid out in the height above the keyboard.
  final bool liftColumn;

  /// Whether the bar sits on top of the keyboard.
  final bool liftBar;

  /// Whether the body (in inset mode) is laid out above the keyboard.
  final bool liftBody;

  /// The page subtree.
  final Widget body;

  /// The backdrop, under everything.
  final Widget? backdrop;

  /// The tab bar, compact mode.
  final Widget? bar;

  /// The side column, wide mode.
  final Widget? column;

  @override
  Iterable<DuoFrameSlot> get slots => DuoFrameSlot.values;

  @override
  Widget? childForSlot(DuoFrameSlot slot) => switch (slot) {
    DuoFrameSlot.backdrop => backdrop,
    DuoFrameSlot.body => body,
    DuoFrameSlot.bar => mode == DuoLayoutMode.compact ? bar : null,
    DuoFrameSlot.column => mode == DuoLayoutMode.wide ? column : null,
  };

  @override
  RenderDuoFrame createRenderObject(BuildContext context) => RenderDuoFrame(
    mode: mode,
    side: side,
    columnOnRight: columnOnRight,
    columnWidth: columnWidth,
    columnInset: columnInset,
    bodyMode: bodyMode,
    systemPadding: systemPadding,
    visibility: visibility,
    keyboard: keyboard,
    liftColumn: liftColumn,
    liftBar: liftBar,
    liftBody: liftBody,
  );

  @override
  void updateRenderObject(BuildContext context, RenderDuoFrame renderObject) {
    renderObject
      ..mode = mode
      ..side = side
      ..columnOnRight = columnOnRight
      ..columnWidth = columnWidth
      ..columnInset = columnInset
      ..bodyMode = bodyMode
      ..systemPadding = systemPadding
      ..visibility = visibility
      ..keyboard = keyboard
      ..liftColumn = liftColumn
      ..liftBar = liftBar
      ..liftBody = liftBody;
  }
}

/// The render object of [DuoFrameLayout].
class RenderDuoFrame extends RenderBox
    with SlottedContainerRenderObjectMixin<DuoFrameSlot, RenderBox> {
  /// Creates the frame's render object.
  RenderDuoFrame({
    required DuoLayoutMode mode,
    required DuoSide side,
    required bool columnOnRight,
    required double columnWidth,
    DuoColumnInset columnInset = DuoColumnInset.overlap,
    required DuoBodyMode bodyMode,
    required EdgeInsets systemPadding,
    required Animation<double> visibility,
    double keyboard = 0,
    bool liftColumn = false,
    bool liftBar = false,
    bool liftBody = false,
  }) : _visibility = visibility,
       _keyboard = keyboard,
       _liftColumn = liftColumn,
       _liftBar = liftBar,
       _liftBody = liftBody,
       _mode = mode,
       _side = side,
       _columnOnRight = columnOnRight,
       _columnWidth = columnWidth,
       _columnInset = columnInset,
       _bodyMode = bodyMode,
       _systemPadding = systemPadding;

  /// See [DuoFrameLayout.mode].
  DuoLayoutMode get mode => _mode;
  DuoLayoutMode _mode;
  set mode(DuoLayoutMode value) {
    if (value == _mode) return;
    _mode = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.side].
  DuoSide get side => _side;
  DuoSide _side;
  set side(DuoSide value) {
    if (value == _side) return;
    _side = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.columnOnRight].
  bool get columnOnRight => _columnOnRight;
  bool _columnOnRight;
  set columnOnRight(bool value) {
    if (value == _columnOnRight) return;
    _columnOnRight = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.columnWidth].
  double get columnWidth => _columnWidth;
  double _columnWidth;
  set columnWidth(double value) {
    if (value == _columnWidth) return;
    _columnWidth = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.bodyMode].
  DuoBodyMode get bodyMode => _bodyMode;
  DuoBodyMode _bodyMode;
  set bodyMode(DuoBodyMode value) {
    if (value == _bodyMode) return;
    _bodyMode = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.systemPadding].
  EdgeInsets get systemPadding => _systemPadding;
  EdgeInsets _systemPadding;
  set systemPadding(EdgeInsets value) {
    if (value == _systemPadding) return;
    _systemPadding = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.keyboard].
  double get keyboard => _keyboard;
  double _keyboard;
  set keyboard(double value) {
    if (value == _keyboard) return;
    _keyboard = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.columnInset].
  DuoColumnInset get columnInset => _columnInset;
  DuoColumnInset _columnInset;
  set columnInset(DuoColumnInset value) {
    if (value == _columnInset) return;
    _columnInset = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.liftColumn].
  bool get liftColumn => _liftColumn;
  bool _liftColumn;
  set liftColumn(bool value) {
    if (value == _liftColumn) return;
    _liftColumn = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.liftBody].
  bool get liftBody => _liftBody;
  bool _liftBody;
  set liftBody(bool value) {
    if (value == _liftBody) return;
    _liftBody = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.liftBar].
  bool get liftBar => _liftBar;
  bool _liftBar;
  set liftBar(bool value) {
    if (value == _liftBar) return;
    _liftBar = value;
    markNeedsLayout();
  }

  /// See [DuoFrameLayout.visibility].
  Animation<double> get visibility => _visibility;
  Animation<double> _visibility;
  set visibility(Animation<double> value) {
    if (value == _visibility) return;
    if (attached) _visibility.removeListener(markNeedsLayout);
    _visibility = value;
    if (attached) _visibility.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _visibility.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _visibility.removeListener(markNeedsLayout);
    super.detach();
  }

  double get _shown => _visibility.value.clamp(0.0, 1.0);

  RenderBox? get _backdrop => childForSlot(DuoFrameSlot.backdrop);
  RenderBox? get _body => childForSlot(DuoFrameSlot.body);
  RenderBox? get _bar => childForSlot(DuoFrameSlot.bar);
  RenderBox? get _column => childForSlot(DuoFrameSlot.column);

  /// Children in paint order: backdrop, body, then the chrome over them.
  List<RenderBox> get _paintOrder => [?_backdrop, ?_body, ?_bar, ?_column];

  bool _reportedShortBar = false;

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth && constraints.hasBoundedHeight,
      'DuoShell and DuoModalScope fill the space they get, so they need '
      'bounded constraints. Got $constraints.',
    );
    size = constraints.biggest;
    final backdrop = _backdrop;
    if (backdrop != null) {
      backdrop.layout(BoxConstraints.tight(size));
      _offset(backdrop, Offset.zero);
    }

    var chrome = EdgeInsets.zero;
    final shown = _shown;
    final keyboard = math.min(_keyboard, size.height);
    final column = _column;
    final bar = _bar;
    if (column != null) {
      final inset = _columnInset == DuoColumnInset.safeArea
          ? (_columnOnRight ? _systemPadding.right : _systemPadding.left)
          : 0.0;
      final width = inset + _columnWidth;
      // Lifted, the column fits above the keyboard, so its bottom-anchored
      // rail and chips ride up with it.
      column.layout(
        BoxConstraints.tightFor(
          width: width,
          height: _liftColumn ? size.height - keyboard : size.height,
        ),
      );
      // Hiding slides the column off its edge.
      final visible = width * shown;
      _offset(
        column,
        Offset(_columnOnRight ? size.width - visible : visible - width, 0),
      );
      chrome = _columnOnRight
          ? EdgeInsets.only(right: visible)
          : EdgeInsets.only(left: visible);
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
      // Lifted, the bar sits on top of the keyboard. Hiding slides it down.
      final base = _liftBar ? keyboard : 0.0;
      _offset(bar, Offset(0, size.height - base - height * shown));
      chrome = EdgeInsets.only(bottom: shown == 0 ? 0 : base + height * shown);
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
              library: 'duo_navigation',
            ),
          );
        }
        return true;
      }());
    }

    final geometry = DuoGeometry(
      mode: _mode,
      side: _side,
      columnOnRight: _columnOnRight,
      bodyMode: _bodyMode,
      systemPadding: _systemPadding,
      chrome: chrome,
      visibility: shown,
      keyboard: _bodyMode == DuoBodyMode.inset && _liftBody ? keyboard : 0,
    );
    final body = _body;
    if (body != null) {
      // In inset mode the body ends above the chrome, and above the keyboard
      // when the frame lifts it.
      final strip = geometry.strip;
      final rect = strip
          .copyWith(bottom: math.max(strip.bottom, geometry.keyboard))
          .deflateRect(Offset.zero & size);
      body.layout(DuoFrameConstraints.tight(rect.size, geometry: geometry));
      _offset(body, rect.topLeft);
    }
  }

  static void _offset(RenderBox child, Offset offset) =>
      (child.parentData! as BoxParentData).offset = offset;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final backdrop = _backdrop;
    if (backdrop != null) _paintChild(context, backdrop, offset);
    final body = _body;
    if (body != null) _paintChild(context, body, offset);
    final shown = _shown;
    final chrome = [?_bar, ?_column];
    if (shown == 0 || shown == 1) _clip.layer = null;
    if (shown == 0) return; // Hidden chrome is not painted.
    if (shown == 1) {
      for (final child in chrome) {
        _paintChild(context, child, offset);
      }
      return;
    }
    // While sliding, keep the chrome inside the frame.
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) {
        for (final child in chrome) {
          _paintChild(context, child, offset);
        }
      },
      oldLayer: _clip.layer,
    );
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  static void _paintChild(
    PaintingContext context,
    RenderBox child,
    Offset offset,
  ) => context.paintChild(
    child,
    (child.parentData! as BoxParentData).offset + offset,
  );

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final children = _shown == 0 ? [?_backdrop, ?_body] : _paintOrder;
    for (final child in children.reversed) {
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
      ..add(EnumProperty<DuoLayoutMode>('mode', _mode))
      ..add(EnumProperty<DuoBodyMode>('bodyMode', _bodyMode))
      ..add(
        FlagProperty(
          'columnOnRight',
          value: _columnOnRight,
          ifTrue: 'column on right',
        ),
      )
      ..add(DoubleProperty('columnWidth', _columnWidth))
      ..add(EnumProperty<DuoColumnInset>('columnInset', _columnInset))
      ..add(DiagnosticsProperty<EdgeInsets>('systemPadding', _systemPadding))
      ..add(DoubleProperty('visibility', _shown))
      ..add(DoubleProperty('keyboard', _keyboard))
      ..add(FlagProperty('liftBody', value: _liftBody, ifTrue: 'lifts body'));
  }
}
