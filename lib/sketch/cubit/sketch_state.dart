part of 'sketch_cubit.dart';

@freezed
class SketchState with _$SketchState {
  const factory SketchState.initial() = _Initial;
  const factory SketchState.success({
    required Sketch sketch,
  }) = _Success;
  const factory SketchState.deleted({
    required Sketch sketch,
  }) = _Deleted;
}
