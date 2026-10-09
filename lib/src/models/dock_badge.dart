import 'package:flutter/foundation.dart';

/// A badge on a tab or an action: a count, a dot, or a short text.
///
/// It is a description; the builders draw it. The package adds [count] and
/// [text] to the item's semantics.
@immutable
class DuoBadge {
  /// A number, such as unread messages.
  const DuoBadge.count(int this.count) : text = null;

  /// A short text, such as "new".
  const DuoBadge.text(String this.text) : count = null;

  /// A dot without content.
  const DuoBadge.dot() : count = null, text = null;

  /// The number, for [DuoBadge.count].
  final int? count;

  /// The text, for [DuoBadge.text].
  final String? text;

  /// Whether this is a dot without content.
  bool get isDot => count == null && text == null;

  /// What the badge says, for display and semantics; null for a dot.
  String? get label => text ?? count?.toString();

  @override
  bool operator ==(Object other) =>
      other is DuoBadge && other.count == count && other.text == text;

  @override
  int get hashCode => Object.hash(count, text);

  @override
  String toString() => isDot ? 'DuoBadge.dot()' : 'DuoBadge($label)';
}
