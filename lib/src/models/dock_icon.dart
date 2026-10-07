import 'package:flutter/widgets.dart';

/// An icon as a description, not a widget, so builders can hand it to any
/// component: one that takes [IconData], an image, or a widget.
///
/// [identity] tells two icons apart, for example to cross-fade when an icon
/// changes; rebuilding the same icon keeps the same identity.
@immutable
sealed class DockIcon {
  const DockIcon._();

  /// An icon from a font, such as `Icons.home`.
  const factory DockIcon(IconData data) = DockDataIcon;

  /// An icon from an image (rendered as a template, like `ImageIcon`).
  const factory DockIcon.image(ImageProvider image) = DockImageIcon;

  /// Any widget as icon. [identity] keys it; without one, the widget's own
  /// key is used, and else its runtime type.
  const factory DockIcon.widget(Widget widget, {Object? identity}) =
      DockWidgetIcon;

  /// Tells this icon apart from others.
  Object get identity;

  /// The icon as a widget, in [size] and [color] (null: from the
  /// surrounding `IconTheme`).
  Widget toWidget({double? size, Color? color});
}

/// A [DockIcon] from a font.
final class DockDataIcon extends DockIcon {
  /// The icon [data].
  const DockDataIcon(this.data) : super._();

  /// The glyph.
  final IconData data;

  @override
  Object get identity => data;

  @override
  Widget toWidget({double? size, Color? color}) =>
      Icon(data, size: size, color: color);

  @override
  bool operator ==(Object other) => other is DockDataIcon && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// A [DockIcon] from an image.
final class DockImageIcon extends DockIcon {
  /// The icon [image].
  const DockImageIcon(this.image) : super._();

  /// The image.
  final ImageProvider image;

  @override
  Object get identity => image;

  @override
  Widget toWidget({double? size, Color? color}) =>
      ImageIcon(image, size: size, color: color);

  @override
  bool operator ==(Object other) =>
      other is DockImageIcon && other.image == image;

  @override
  int get hashCode => image.hashCode;
}

/// A [DockIcon] that is a widget.
final class DockWidgetIcon extends DockIcon {
  /// The icon [widget], told apart by [identity].
  const DockWidgetIcon(this.widget, {Object? identity})
    : _identity = identity,
      super._();

  /// The widget. [toWidget] ignores size and color for it.
  final Widget widget;

  final Object? _identity;

  @override
  Object get identity => _identity ?? widget.key ?? widget.runtimeType;

  @override
  Widget toWidget({double? size, Color? color}) => widget;

  @override
  bool operator ==(Object other) =>
      other is DockWidgetIcon &&
      other.widget == widget &&
      other._identity == _identity;

  @override
  int get hashCode => Object.hash(widget, _identity);
}
