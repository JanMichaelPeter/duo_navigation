import 'package:flutter/widgets.dart';

/// Keeps focus on the same tab or action when a frame switches between the
/// compact and the wide layout: the tab bar item and the rail item of a tab
/// share an id, and so do an action in the title bar and its chip in the
/// column.
///
/// The frame owns one registry. Chrome items register a [DockFocusMarker];
/// before a mode switch the frame asks which marked item has focus, and
/// after it focuses the first focusable widget inside the item with the same
/// id.
class DockFocusRegistry {
  final Map<Object, BuildContext> _markers = {};

  /// The id of the marked item that has focus, if any belongs to this
  /// registry.
  Object? focusedId() {
    final context = FocusManager.instance.primaryFocus?.context;
    final marker = context?.findAncestorStateOfType<_DockFocusMarkerState>();
    if (marker == null || !identical(marker._registry, this)) return null;
    return marker.widget.id;
  }

  /// Focuses the item with [id] after the next frame, when the new layout is
  /// built.
  void restoreAfterFrame(Object id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _markers[id];
      if (context == null || !context.mounted) return;
      _firstFocusable(context)?.requestFocus();
    });
  }

  static FocusNode? _firstFocusable(BuildContext context) {
    FocusNode? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget is Focus) {
        Element? child;
        element.visitChildElements((c) => child ??= c);
        // No dependency: this runs outside any build.
        final node = child == null
            ? null
            : Focus.maybeOf(child!, createDependency: false);
        if (node != null && node.canRequestFocus && !node.skipTraversal) {
          found = node;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    (context as Element).visitChildElements(visit);
    return found;
  }
}

/// Provides a frame's [DockFocusRegistry] to its chrome and pages.
class DockFocusRegistryScope extends InheritedWidget {
  /// Provides [registry] to [child].
  const DockFocusRegistryScope({
    super.key,
    required this.registry,
    required super.child,
  });

  /// The frame's registry.
  final DockFocusRegistry registry;

  /// The registry of the nearest frame, or null.
  static DockFocusRegistry? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DockFocusRegistryScope>()?.registry;

  @override
  bool updateShouldNotify(DockFocusRegistryScope oldWidget) =>
      !identical(registry, oldWidget.registry);
}

/// Registers a chrome item ([id]: a tab or an action) with the frame's
/// [DockFocusRegistry].
class DockFocusMarker extends StatefulWidget {
  /// Marks [child] as the item [id].
  const DockFocusMarker({super.key, required this.id, required this.child});

  /// The item's identity, the same in both layouts.
  final Object id;

  /// The item.
  final Widget child;

  @override
  State<DockFocusMarker> createState() => _DockFocusMarkerState();
}

class _DockFocusMarkerState extends State<DockFocusMarker> {
  DockFocusRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = DockFocusRegistryScope.maybeOf(context);
    if (!identical(registry, _registry)) {
      _unregister();
      _registry = registry;
      _register();
    }
  }

  @override
  void didUpdateWidget(DockFocusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {
      _unregister(oldWidget.id);
      _register();
    }
  }

  void _register() => _registry?._markers[widget.id] = context;

  void _unregister([Object? id]) {
    final markers = _registry?._markers;
    final key = id ?? widget.id;
    if (markers != null && identical(markers[key], context)) {
      markers.remove(key);
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
