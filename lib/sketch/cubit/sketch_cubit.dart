import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

part 'sketch_state.dart';
part 'sketch_cubit.freezed.dart';

class SketchCubit extends Cubit<SketchState> {
  SketchRepository? _repopository;
  SketchRepository get _repo => _repopository!;

  SketchCubit() : super(const SketchState.initial());

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
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        if (sketch.lines.isEmpty) return;

        final line = sketch.lines.last;
        final copy = e.copyWith(
          redoList: [...e.redoList, line],
          sketch: sketch.copyWith(
            lines: sketch.lines.sublist(
              0,
              sketch.lines.length - 1,
            ),
          ),
        );
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void redo() async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        if (e.redoList.isEmpty) return;

        final line = e.redoList.last;
        final copy = e.copyWith(
          redoList: e.redoList.sublist(0, e.redoList.length - 1),
          sketch: sketch.copyWith(
            lines: [...sketch.lines, line],
          ),
        );
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void begin(
    Offset point,
    Size size,
  ) async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final copy = e.copyWith(
          activeLine: SketchLine(
            points: [_scaled(point, size)],
            color: sketch.color,
            strokeWidth: sketch.strokeWidth,
          ),
        );
        emit(copy);
      },
    );
  }

  void append(
    Offset point,
    Size size,
  ) async {
    await state.mapOrNull(
      success: (e) async {
        final line = e.activeLine;
        if (line == null) return;

        final copy = e.copyWith(
          activeLine: line.copyWith(
            points: [
              ...line.points,
              _scaled(point, size),
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
        final copy = e.copyWith(
          sketch: sketch.copyWith(lines: [...sketch.lines, line]),
          activeLine: null,
        );
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void clear() async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final copy = e.copyWith(
          sketch: sketch.copyWith(lines: const []),
          activeLine: null,
        );
        emit(copy);
        await _repo.save(copy.sketch);
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

  void setColor(Color color) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(color: color);
        emit(copy);
        await _repo.save(copy.sketch);
      },
    );
  }

  void setStrokeWidth(double strokeWidth) async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(strokeWidth: strokeWidth);
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

  Offset _scaled(Offset point, Size size) {
    return point.scale(1.0 / size.width, 1.0 / size.height);
  }
}
