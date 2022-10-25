import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/utils/utils.dart';

void main() {
  late UndoStack stack;

  setUp(() {
    stack = UndoStack(1);
  });

  test('initial state', () {
    expect(stack.state, 1);
    expect(stack.canRedo, false);
    expect(stack.canUndo, false);
    expect(stack.capacity, 100);
  });
  test('modify(2)', () {
    stack.modify(2);

    expect(stack.state, 2);
    expect(stack.canRedo, false);
    expect(stack.canUndo, true);
    expect(stack.capacity, 100);
  });

  test('when canUndo is false then undo() throws a exception', () {
    expect(stack.canUndo, false);
    expect(() => stack.undo(), throwsException);
  });

  test('when canRedo is false then redo() throws a exception', () {
    expect(stack.canRedo, false);
    expect(() => stack.redo(), throwsException);
  });

  test('modify and undo and redo', () {
    stack.modify(2);
    expect(stack.state, 2);

    stack.undo();
    expect(stack.state, 1);

    stack.redo();
    expect(stack.state, 2);
  });

  test('same state is ignored', () {
    stack.modify(2);
    stack.modify(2);
    stack.undo();
    expect(stack.canUndo, false);
  });

  test('when reset is called then state is the value', () {
    stack.modify(2);
    stack.reset(3);
    expect(stack.state, 3);
    expect(stack.canUndo, false);
    expect(stack.canRedo, false);
  });
}
