part of 'sketch_cubit.dart';

enum SketchMode {
  pen,
  eraser,
}

@freezed
class SketchState with _$SketchState {
  const factory SketchState.initial() = _Initial;
  const factory SketchState.success({
    @Default(false) bool canUndo,
    @Default(false) bool canRedo,
    required Sketch sketch,
    SketchLine? activeLine,
    @Default(SketchMode.pen) SketchMode mode,
  }) = _Success;
  const factory SketchState.deleted({
    required Sketch sketch,
  }) = _Deleted;
}
