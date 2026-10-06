/// Stable order for the animated column: [next] in its order, with ids that
/// are leaving kept next to their former neighbours so they fade out in place.
List<Object> mergeOrder(List<Object> previous, List<Object> next) {
  final result = List<Object>.of(next);
  final nextSet = next.toSet();
  for (var i = 0; i < previous.length; i++) {
    final id = previous[i];
    if (nextSet.contains(id) || result.contains(id)) continue;
    var insertAt = 0;
    for (var j = i - 1; j >= 0; j--) {
      final idx = result.indexOf(previous[j]);
      if (idx >= 0) {
        insertAt = idx + 1;
        break;
      }
    }
    result.insert(insertAt, id);
  }
  return result;
}
