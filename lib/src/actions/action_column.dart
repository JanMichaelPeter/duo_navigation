// 0.0.1 code that the 0.1.0 redesign replaces (#42).
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../builders/builders.dart';
import '../config/navigation.dart';
import '../models/action.dart';
import '../models/enums.dart';
import '../keys.dart';
import 'action_host.dart';
import 'action_presence.dart';
import 'merge_order.dart';

@immutable
class _ScopedKey {
  const _ScopedKey(this.owner, this.id);
  final Object owner;
  final Object id;

  @override
  bool operator ==(Object other) =>
      other is _ScopedKey && identical(other.owner, owner) && other.id == id;

  @override
  int get hashCode => Object.hash(identityHashCode(owner), id);
}

Object _keyFor(DockActionRegistration owner, DockAction action) =>
    action.shared ? action.id : _ScopedKey(owner, action.id);

class _Item {
  _Item(this.key, this.action, this.owner, {required this.animateIn});
  final Object key;
  DockAction action;
  DockActionRegistration owner;
  bool visible = true;
  final bool animateIn;
}

/// The animated action stack inside the side column. Anchored to the bottom,
/// so the back button (always last) sits right above the rail and never moves
/// when trailing actions above it change.
class DockActionColumn extends StatefulWidget {
  const DockActionColumn({super.key, required this.host});

  final DockActionHost host;

  @override
  State<DockActionColumn> createState() => _DockActionColumnState();
}

class _DockActionColumnState extends State<DockActionColumn> {
  List<_Item> _items = [];

  @override
  void initState() {
    super.initState();
    widget.host.addListener(_onHostChanged);
    _items = _reconcile(initial: true);
  }

  @override
  void didUpdateWidget(DockActionColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host != widget.host) {
      oldWidget.host.removeListener(_onHostChanged);
      widget.host.addListener(_onHostChanged);
      _items = [];
      _items = _reconcile(initial: true);
    }
  }

  @override
  void dispose() {
    widget.host.removeListener(_onHostChanged);
    super.dispose();
  }

  void _onHostChanged() {
    if (!mounted) return;
    setState(() => _items = _reconcile(initial: false));
  }

  List<_Item> _reconcile({required bool initial}) {
    final owner = widget.host.active;
    final next = <Object, DockAction>{};
    if (owner != null) {
      for (final a in owner.actions) {
        if (a.canHoist) next[_keyFor(owner, a)] = a;
      }
    }
    final previous = {for (final i in _items) i.key: i};
    final order = mergeOrder(
      _items.map((i) => i.key).toList(),
      next.keys.toList(),
    );

    final result = <_Item>[];
    for (final key in order) {
      final action = next[key];
      final existing = previous[key];
      if (action != null) {
        if (existing != null) {
          existing
            ..action = action
            ..owner = owner!
            ..visible = true;
          result.add(existing);
        } else {
          result.add(_Item(key, action, owner!, animateIn: !initial));
        }
      } else if (existing != null) {
        result.add(existing..visible = false);
      }
    }
    return result;
  }

  void _remove(Object key) {
    if (!mounted) return;
    setState(() => _items.removeWhere((i) => i.key == key && !i.visible));
  }

  @override
  Widget build(BuildContext context) {
    final config = DockNavigation.of(context);
    final builders = DockBuilders.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        reverse: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in _items)
              ActionPresence(
                key: ValueKey<Object>(item.key),
                visible: item.visible,
                animateIn: item.animateIn,
                duration: config.actionAnimationDuration,
                curve: config.actionAnimationCurve,
                transitionBuilder: builders.buildActionTransition,
                onDismissed: () => _remove(item.key),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: config.actionSpacing / 2,
                  ),
                  // Centered on the column axis, like the rail, whatever the
                  // transition does horizontally.
                  child: Center(
                    child: KeyedSubtree(
                      key: DockKeys.action(item.action.id),
                      child: builders.buildAction(
                        context,
                        item.owner.guarded(item.action),
                        DockActionPlacement.sideColumn,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
