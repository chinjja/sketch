import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sketch/model/model.dart';
import 'package:sketch/service/sketch_service.dart';
import 'package:sketch/utils/utils.dart';
import 'package:uuid/uuid.dart';

part 'sketch_state.dart';
part 'sketch_cubit.freezed.dart';

class SketchCubit extends Cubit<SketchState> {
  SketchService? _service;
  final UndoStack<Sketch?> _stack;

  SketchCubit([UndoStack<Sketch?>? stack])
      : _stack = stack ?? UndoStack(null),
        super(const SketchState.initial());

  StreamSubscription? _eraseSubscription;

  @override
  void emit(SketchState state) {
    super.emit(
      state.maybeMap(
        success: (e) => e.copyWith(
          canUndo: _stack.canUndo,
          canRedo: _stack.canRedo,
        ),
        orElse: () => state,
      ),
    );
  }

  @override
  Future<void> close() async {
    _eraseSubscription?.cancel();
    _save();
    return super.close();
  }

  void started(SketchService service) {
    assert(_service == null);
    _service = service;
    _eraseSubscription = _eraseTask.listen((event) {});
  }

  void sketch(String sketchId) async {
    emit(const SketchState.loading());
    final sketch = await _service!.getById(sketchId);
    _stack.reset(sketch);
    if (sketch != null) {
      emit(
        state.maybeMap(
          success: (e) => e.copyWith(sketch: sketch),
          orElse: () => SketchState.success(sketch: sketch),
        ),
      );
    }
  }

  void _save() async {
    await state.mapOrNull(success: (e) async {
      await _service!.save(e.sketch);
    });
  }

  void _modify(Sketch sketch) {
    _stack.modify(sketch);
  }

  void undo() async {
    state.mapOrNull(success: (e) {
      if (!_stack.canUndo) return;

      _stack.undo();
      emit(e.copyWith(
        sketch: _stack.state!,
        canUndo: _stack.canUndo,
        canRedo: _stack.canRedo,
      ));
    });
  }

  void redo() async {
    state.mapOrNull(success: (e) {
      if (!_stack.canRedo) return;

      _stack.redo();
      emit(e.copyWith(
        sketch: _stack.state!,
        canUndo: _stack.canUndo,
        canRedo: _stack.canRedo,
      ));
    });
  }

  Offset? _panStart;

  void begin(int pointerCount, Offset point, Size size) async {
    await state.mapOrNull(
      success: (e) async {
        switch (pointerCount) {
          case 1:
            _panStart = null;
            switch (e.mode) {
              case SketchMode.pen:
                _penStarted(e, point - e.sketch.viewport.offset, size);
                break;
              case SketchMode.eraser:
                _eraserStarted(e, point - e.sketch.viewport.offset, size);
                break;
            }
            break;
          case 2:
            _panStart = point;
            break;
        }
      },
    );
  }

  void _eraserStarted(_Success state, Offset point, Size size) {
    _prev = point;
  }

  void _penStarted(_Success state, Offset point, Size size) {
    final sketch = state.sketch;
    final copy = state.copyWith(
      activeLine: SketchLine(
        points: [point],
        pen: sketch.pen,
      ),
      sketch: sketch.copyWith.viewport(
        width: size.width,
        height: size.height,
      ),
    );
    emit(copy);
  }

  void append(Offset point) async {
    await state.mapOrNull(
      success: (e) async {
        if (_panStart == null) {
          switch (e.mode) {
            case SketchMode.pen:
              _penUpdate(e, point - e.sketch.viewport.offset);
              break;
            case SketchMode.eraser:
              _eraserUpdate(e, point - e.sketch.viewport.offset);
              break;
          }
        } else {
          final viewport = e.sketch.viewport;
          final copy = e.copyWith.sketch.viewport(
            x: viewport.x + (point - _panStart!).dx,
            y: viewport.y + (point - _panStart!).dy,
          );
          _panStart = point;
          emit(copy);
        }
      },
    );
  }

  void _penUpdate(_Success state, Offset point) {
    final line = state.activeLine;
    if (line == null) return;

    final copy = state.copyWith(
      activeLine: line.addPoints([point]),
    );
    emit(copy);
  }

  void _eraserUpdate(_Success state, Offset point) {
    _eraseSubject.add(point);
  }

  void end() async {
    await state.mapOrNull(
      success: (e) async {
        var line = e.activeLine;
        if (line == null) return;

        if (line.points.length == 1) {
          line = line.addPoints([line.points.first]);
        }

        final copy = e.copyWith(
          sketch: e.sketch.setLayer(e.sketch.activeLayer.addLine(line)),
          activeLine: null,
        );
        _modify(copy.sketch);
        emit(copy);
      },
    );
  }

  void clear() async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith(
          sketch: e.sketch.clear(),
          activeLine: null,
        );
        _prev = null;
        _modify(copy.sketch);
        emit(copy);
      },
    );
  }

  void mode(SketchMode mode) {
    state.mapOrNull(
      success: (e) async {
        emit(e.copyWith(mode: mode));
      },
    );
  }

  Offset? _prev;
  late final _eraseSubject = PublishSubject<Offset>();
  late final _eraseTask = _eraseSubject.exhaustMap((point) {
    return state.mapOrNull(
          success: (e) async {
            final layer = await _erase(e.sketch.activeLayer, _prev!, point);
            _prev = point;
            final copy = e.copyWith(
              sketch: e.sketch.setLayer(layer),
            );
            _modify(copy.sketch);
            emit(copy);
          },
        )?.asStream() ??
        const Stream.empty();
  });

  Future<SketchLayer> _erase(SketchLayer layer, Offset p1, Offset p2) async {
    final removed = <int>[];
    for (int i = layer.lines.length - 1; i >= 0; i--) {
      if (layer.lines[i].isCollide(p1, p2)) {
        removed.add(i);
      }
    }
    if (removed.isNotEmpty) {
      final lines = [...layer.lines];
      for (final i in removed) {
        lines.removeAt(i);
      }
      return layer.copyWith(lines: lines);
    }
    return layer;
  }

  void delete() async {
    await state.mapOrNull(
      success: (e) async {
        await _service!.delete(e.sketch);
        emit(SketchState.deleted(sketch: e.sketch));
      },
    );
  }

  void addLayer() async {
    await state.mapOrNull(
      success: (e) async {
        final layer = SketchLayer(id: const Uuid().v4());
        final copy = e.copyWith(
          sketch: e.sketch.addLayer(layer),
        );
        _modify(copy.sketch);
        emit(copy);
      },
    );
  }

  void deleteLayer(SketchLayer layer) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith(
          sketch: e.sketch.removeLayer(layer),
        );
        _modify(copy.sketch);
        emit(copy);
      },
    );
  }

  void reorderLayer(int oldIndex, int newIndex) async {
    await state.mapOrNull(
      success: (e) async {
        if (oldIndex < newIndex) {
          newIndex--;
        }
        final sketch = e.sketch;
        final layers = [...sketch.layers];
        final layer = layers[oldIndex];
        layers.removeAt(oldIndex);
        layers.insert(newIndex, layer);
        final copy = e.copyWith.sketch(layers: layers);
        emit(copy);
      },
    );
  }

  void updateLayerTitle(SketchLayer layer, String title) async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final copy = e.copyWith.sketch(
            layers: sketch.layers
                .map((element) => element.id == layer.id
                    ? element.copyWith(title: title)
                    : element)
                .toList());
        emit(copy);
      },
    );
  }

  void toggleVisibleLayer(SketchLayer layer) async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final layers = sketch.layers
            .map((e) => e.id == layer.id ? e.copyWith(visible: !e.visible) : e)
            .toList();
        final copy = e.copyWith.sketch(layers: layers);
        emit(copy);
      },
    );
  }

  void activeLayer(SketchLayer layer) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith(sketch: e.sketch.setActiveLayer(layer));
        emit(copy);
      },
    );
  }

  void setColor(Color color) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch.pen(color: color);
        emit(copy);
      },
    );
  }

  void setStrokeWidth(double strokeWidth) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch.pen(strokeWidth: strokeWidth);
        emit(copy);
      },
    );
  }

  void setTitle(String title) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(title: title);
        emit(copy);
      },
    );
  }
}
