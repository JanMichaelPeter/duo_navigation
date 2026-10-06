import 'package:nav_dock/src/actions/merge_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new actions take the new order, leaving ones stay in place', () {
    expect(mergeOrder(['a', 'back'], ['b', 'back']), ['a', 'b', 'back']);
  });

  test('leaving actions keep their neighbours', () {
    expect(mergeOrder(['x', 'y', 'back'], ['back']), ['x', 'y', 'back']);
  });

  test('persisting ids are not duplicated', () {
    expect(mergeOrder(['a', 'back'], ['a', 'back']), ['a', 'back']);
  });

  test('empty transitions', () {
    expect(mergeOrder([], ['a']), ['a']);
    expect(mergeOrder(['a'], []), ['a']);
  });
}
