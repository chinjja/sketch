import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';
import 'package:uuid/uuid.dart';

part 'sketch_state.dart';
part 'sketch_cubit.freezed.dart';

class SketchCubit extends Cubit<SketchState> {
  SketchRepository? _repopository;
  SketchRepository get _repo => _repopository!;
  final _undos = <_Success>[];
  final _redos = <_Success>[];

  SketchCubit() : super(const SketchState.initial());

  bool get _canUndo => _undos.isNotEmpty;
  bool get _canRedo => _redos.isNotEmpty;

  void started(SketchRepository repository) {
    assert(_repopository == null);
    _repopository = repository;
  }

  void sketch(Sketch sketch) {
    emit(
      state.maybeMap(
        success: (e) => e.copyWith(sketch: sketch),
        orElse: () => SketchState.success(sketch: sketch),
      ),
    );
  }

  void undo() async {
    if (state is _Success && _canUndo) {
      final e = _undos.removeLast();
      _redos.add(state as _Success);
      emit(e.copyWith(
        canUndo: _canUndo,
        canRedo: _canRedo,
      ));
    }
  }

  void redo() async {
    if (state is _Success && _canRedo) {
      final e = _redos.removeLast();
      _undos.add(state as _Success);
      emit(e.copyWith(
        canUndo: _canUndo,
        canRedo: _canRedo,
      ));
    }
  }

  _Success _wrap(_Success newState) {
    return state.maybeMap(
      success: (e) {
        if (_undos.isEmpty || _undos.last != newState) {
          _redos.clear();
          _undos.add(e.copyWith(activeLine: null));
        }
        return newState.copyWith(
          canUndo: _canUndo,
          canRedo: _canRedo,
        );
      },
      orElse: () => newState,
    );
  }

  void begin(Offset point, Size size) async {
    await state.mapOrNull(
      success: (e) async {
        if (e.mode != SketchMode.pen) {
          _erase(point);
          return;
        }

        final sketch = e.sketch;
        final copy = e.copyWith(
          activeLine: SketchLine(
            points: [point],
            pen: sketch.pen,
          ),
          sketch: sketch.copyWith(
              viewport: SketchViewport(
            width: size.width,
            height: size.height,
          )),
        );
        emit(copy);
      },
    );
  }

  void append(Offset point) async {
    await state.mapOrNull(
      success: (e) async {
        if (e.mode != SketchMode.pen) {
          _erase(point);
          return;
        }

        final line = e.activeLine;
        if (line == null) return;

        final copy = e.copyWith(
          activeLine: line.copyWith(
            points: [
              ...line.points,
              point,
            ],
          ),
        );
        emit(copy);
      },
    );
  }

  void end() async {
    await state.mapOrNull(
      success: (e) async {
        var line = e.activeLine;
        if (line == null) return;

        if (line.points.length == 1) {
          line = line.copyWith(points: [...line.points, line.points.first]);
        }

        final sketch = e.sketch;
        final layers = sketch.layers
            .map((e) => e.id == sketch.activeLayerId
                ? e.copyWith(lines: [...e.lines, line!])
                : e)
            .toList();
        final copy = e.copyWith(
          sketch: sketch.copyWith(layers: layers),
          activeLine: null,
        );
        emit(_wrap(copy));
        await _repo.save(copy.sketch);
      },
    );
  }

  void clear() async {
    await state.mapOrNull(
      success: (e) async {
        final layer = SketchLayer(id: const Uuid().v4());
        final sketch = e.sketch.copyWith(
          activeLayerId: layer.id,
          layers: [layer],
        );
        final res = await _repo.save(sketch);
        final copy = e.copyWith(
          sketch: res,
          activeLine: null,
        );
        emit(_wrap(copy));
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

  void _erase(Offset point) async {
    await state.mapOrNull(
      success: (e) async {
        final layers = e.sketch.layers.map((layer) {
          if (layer.id == e.sketch.activeLayerId) {
            final list = <int>[];
            for (int i = layer.lines.length - 1; i >= 0; i--) {
              if (layer.lines[i].isCollide(point)) {
                list.add(i);
              }
            }
            if (list.isNotEmpty) {
              final lines = [...layer.lines];
              for (final i in list) {
                lines.removeAt(i);
              }
              return layer.copyWith(lines: lines);
            }
          }
          return layer;
        }).toList();
        final copy = e.copyWith(
          sketch: e.sketch.copyWith(layers: layers),
        );
        emit(_wrap(copy));
        final res = await _repo.save(copy.sketch);
      },
    );
  }

  void delete() async {
    await state.mapOrNull(
      success: (e) async {
        await _repo.delete(e.sketch);
        emit(SketchState.deleted(sketch: e.sketch));
      },
    );
  }

  void addLayer() async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final layer = SketchLayer(id: const Uuid().v4());
        final copy = e.copyWith(
          sketch: sketch.copyWith(layers: [...sketch.layers, layer]),
        );
        emit(_wrap(copy));
        await _repo.save(copy.sketch);
      },
    );
  }

  void deleteLayer(SketchLayer layer) async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final copy = e.copyWith.sketch(
            layers: sketch.layers
                .where((element) => element.id != layer.id)
                .toList());
        emit(_wrap(copy));
        await _repo.save(copy.sketch);
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
        await _repo.save(copy.sketch);
      },
    );
  }

  void activeLayer(SketchLayer layer) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(activeLayerId: layer.id);
        emit(_wrap(copy));
        await _repo.save(copy.sketch);
      },
    );
  }

  void setColor(Color color) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch.pen(color: color);
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void setStrokeWidth(double strokeWidth) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch.pen(strokeWidth: strokeWidth);
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void setTitle(String title) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(title: title);
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }
}
