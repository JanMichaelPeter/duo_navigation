import 'package:flutter/widgets.dart';

/// An icon as a description, not a widget, so builders can hand it to any
/// component: one that takes [IconData], an image, or a widget.
///
/// [identity] tells two icons apart, for example to cross-fade when an icon
/// changes; rebuilding the same icon keeps the same identity.
@immutable
sealed class DuoIcon {
  const DuoIcon._();

  /// An icon from a font, such as `Icons.home`.
  const factory DuoIcon(IconData data) = DuoDataIcon;

  /// An icon from an image (rendered as a template, like `ImageIcon`).
  const factory DuoIcon.image(ImageProvider image) = DuoImageIcon;

  /// Any widget as icon. [identity] keys it; without one, the widget's own
  /// key is used, and else its runtime type.
  const factory DuoIcon.widget(Widget widget, {Object? identity}) =
      DuoWidgetIcon;

  /// The platform's back icon (a chevron on iOS and macOS, an arrow
  /// elsewhere), resolved by the builders.
  static const DuoIcon back = DuoPlatformIcon(DuoPlatformIconKind.back);

  /// The platform's close icon, resolved by the builders.
  static const DuoIcon close = DuoPlatformIcon(DuoPlatformIconKind.close);

  /// Tells this icon apart from others.
  Object get identity;

  /// The icon as a widget, in [size] and [color] (null: from the
  /// surrounding `IconTheme`).
  ///
  /// Platform icons ([DuoIcon.back], [DuoIcon.close]) depend on the design
  /// system and throw here; builders resolve them (`DuoMaterial.icon` does).
  Widget toWidget({double? size, Color? color});
}

/// A [DuoIcon] from a font.
final class DuoDataIcon extends DuoIcon {
  /// The icon [data].
  const DuoDataIcon(this.data) : super._();

  /// The glyph.
  final IconData data;

  @override
  Object get identity => data;

  @override
  Widget toWidget({double? size, Color? color}) =>
      Icon(data, size: size, color: color);

  @override
  bool operator ==(Object other) => other is DuoDataIcon && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// A [DuoIcon] from an image.
final class DuoImageIcon extends DuoIcon {
  /// The icon [image].
  const DuoImageIcon(this.image) : super._();

  /// The image.
  final ImageProvider image;

  @override
  Object get identity => image;

  @override
  Widget toWidget({double? size, Color? color}) =>
      ImageIcon(image, size: size, color: color);

  @override
  bool operator ==(Object other) =>
      other is DuoImageIcon && other.image == image;

  @override
  int get hashCode => image.hashCode;
}

/// A [DuoIcon] that is a widget.
final class DuoWidgetIcon extends DuoIcon {
  /// The icon [widget], told apart by [identity].
  const DuoWidgetIcon(this.widget, {Object? identity})
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
      other is DuoWidgetIcon &&
      other.widget == widget &&
      other._identity == _identity;

  @override
  int get hashCode => Object.hash(widget, _identity);
}

/// Which platform icon a [DuoPlatformIcon] stands for.
enum DuoPlatformIconKind {
  /// Back: a chevron or an arrow, depending on the platform.
  back,

  /// Close: a cross.
  close,
}

/// A platform icon ([DuoIcon.back], [DuoIcon.close]) that the builders
/// resolve in their design system.
final class DuoPlatformIcon extends DuoIcon {
  /// The platform icon of [kind].
  const DuoPlatformIcon(this.kind) : super._();

  /// Back or close.
  final DuoPlatformIconKind kind;

  @override
  Object get identity => kind;

  @override
  Widget toWidget({
    double? size,
    Color? color,
  }) => throw FlutterError.fromParts([
    ErrorSummary('DuoIcon.${kind.name} has no widget of its own.'),
    ErrorDescription(
      'Platform icons depend on the design system, so builders resolve them.',
    ),
    ErrorHint(
      'In a builder, switch over the DuoIcon and draw DuoPlatformIcon '
      "yourself, or use DuoMaterial.icon from 'package:duo_navigation/material.dart'.",
    ),
  ]);

  @override
  bool operator ==(Object other) =>
      other is DuoPlatformIcon && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}
