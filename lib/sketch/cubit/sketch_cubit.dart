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
        final line = SketchLine(
          points: [_scaled(point, size)],
          color: sketch.color,
          strokeWidth: sketch.strokeWidth,
        );
        final copy = e.copyWith.sketch(lines: [...sketch.lines, line]);
        emit(copy);

        await _repo.save(copy.sketch);
      },
    );
  }

  void append(
    Offset point,
    Size size,
  ) async {
    await state.mapOrNull(
      success: (e) async {
        final sketch = e.sketch;
        final lines = [...sketch.lines];
        lines.last = lines.last.copyWith(
          points: [
            ...lines.last.points,
            _scaled(point, size),
          ],
        );
        final copy = e.copyWith.sketch(lines: lines);
        emit(copy);

        await _repo.save(copy.sketch);
      },
    );
  }

  void end() {
    state.mapOrNull(
      success: (e) {
        final sketch = e.sketch;
        if (sketch.lines.last.points.length == 1) {
          append(sketch.lines.last.points[0], const Size(1, 1));
        }
      },
    );
  }

  void clear() async {
    await state.mapOrNull(
      success: (e) async {
        final copy = e.copyWith.sketch(lines: const []);
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
