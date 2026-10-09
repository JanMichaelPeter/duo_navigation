import 'package:flutter/foundation.dart';

/// Keys that duo_navigation puts around the bar, the column, the rail and every
/// action, whatever builder draws them. Find them in tests with
/// `find.byKey(DockKeys.action('share'))`.
///
/// The package applies these keys itself, around the output of the builders,
/// so custom builders don't need to (and should not reuse them).
abstract final class DockKeys {
  /// The compact tab bar.
  static const Key bar = ValueKey<_DockKey>(_DockKey('bar'));

  /// The wide side column.
  static const Key column = ValueKey<_DockKey>(_DockKey('column'));

  /// The rail of tabs in the side column.
  static const Key rail = ValueKey<_DockKey>(_DockKey('rail'));

  /// The tab with [id] (`DockTab.id`), in the tab bar or in the rail.
  static Key tab(Object id) => ValueKey<_DockKey>(_DockKey('tab', id));

  /// The action with [id], in the title bar or as a chip in the column.
  static Key action(Object id) => ValueKey<_DockKey>(_DockKey('action', id));
}

@immutable
class _DockKey {
  const _DockKey(this.kind, [this.id]);

  final String kind;
  final Object? id;

  @override
  bool operator ==(Object other) =>
      other is _DockKey && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => id == null ? 'DockKeys.$kind' : 'DockKeys.$kind($id)';
}
