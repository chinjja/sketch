part of 'sketch_cubit.dart';

@freezed
class SketchState with _$SketchState {
  const factory SketchState.initial() = _Initial;
  const factory SketchState.success({
    @Default(false) bool canUndo,
    @Default(false) bool canRedo,
    required Sketch sketch,
    SketchLine? activeLine,
  }) = _Success;
  const factory SketchState.deleted({
    required Sketch sketch,
  }) = _Deleted;
}
