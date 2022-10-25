import 'dart:collection';

class UndoStack<T> {
  final _undoList = Queue<T>();
  final _redoList = Queue<T>();
  T state;

  final int capacity;

  UndoStack(this.state, {this.capacity = 100});

  void reset(T state) {
    this.state = state;
    _undoList.clear();
    _redoList.clear();
  }

  void modify(T state) {
    if (this.state == state) return;

    _redoList.clear();
    if (_undoList.length >= capacity) {
      _undoList.removeFirst();
    }
    _undoList.addLast(this.state);
    this.state = state;
  }

  void undo() {
    if (!canUndo) throw Exception('cannot undo');

    _redoList.add(state);
    state = _undoList.removeLast();
  }

  void redo() {
    if (!canRedo) throw Exception('cannot redo');

    _undoList.add(state);
    state = _redoList.removeLast();
  }

  bool get canUndo => _undoList.isNotEmpty;
  bool get canRedo => _redoList.isNotEmpty;
}
