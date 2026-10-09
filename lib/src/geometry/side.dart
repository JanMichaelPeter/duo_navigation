/// Which edge the side column sits on in wide mode, relative to the text
/// direction: `end` is the right edge in left-to-right layouts.
enum DuoSide {
  /// Left in left-to-right layouts, right in right-to-left layouts.
  start,

  /// Right in left-to-right layouts, left in right-to-left layouts.
  end,
}
