import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

part 'sketch_state.dart';
part 'sketch_cubit.freezed.dart';

class SketchCubit extends Cubit<SketchState> {
  final SketchRepository _repo;

  SketchCubit(this._repo) : super(const SketchState.initial());

  void init(Sketch sketch) {
    emit(
      state.maybeMap(
        success: (e) => e.copyWith(sketch: sketch),
        orElse: () => SketchState.success(sketch: sketch),
      ),
    );
  }

  void begin(
    Offset point,
    Size size,
  ) {
    state.mapOrNull(
      success: (e) {
        final sketch = e.sketch;
        final line = SketchLine(
          points: [_scaled(point, size)],
          color: sketch.color,
          strokeWidth: sketch.strokeWidth,
        );
        final copy = e.copyWith.sketch(lines: [...sketch.lines, line]);
        emit(copy);

        _repo.save(copy.sketch);
      },
    );
  }

  void append(
    Offset point,
    Size size,
  ) {
    state.mapOrNull(
      success: (e) {
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

        _repo.save(copy.sketch);
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

  void clear() {
    state.mapOrNull(
      success: (e) {
        final copy = e.copyWith.sketch(lines: const []);
        emit(copy);
        _repo.save(copy.sketch);
      },
    );
  }

  void delete() {
    state.mapOrNull(
      success: (e) async {
        await _repo.delete(e.sketch);
        emit(SketchState.deleted(sketch: e.sketch));
      },
    );
  }

  void setColor(Color color) {
    state.mapOrNull(
      success: (e) {
        final copy = e.copyWith.sketch(color: color);
        emit(copy);
        _repo.save(copy.sketch);
      },
    );
  }

  void setStrokeWidth(double strokeWidth) {
    state.mapOrNull(
      success: (e) {
        final copy = e.copyWith.sketch(strokeWidth: strokeWidth);
        emit(copy);
        _repo.save(copy.sketch);
      },
    );
  }

  void setTitle(String title) {
    state.mapOrNull(
      success: (e) {
        final copy = e.copyWith.sketch(title: title);
        emit(copy);
        _repo.save(copy.sketch);
      },
    );
  }

  Offset _scaled(Offset point, Size size) {
    return point.scale(1.0 / size.width, 1.0 / size.height);
  }
}
