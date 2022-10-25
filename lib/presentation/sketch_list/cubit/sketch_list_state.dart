part of 'sketch_list_cubit.dart';

@freezed
class SketchListState with _$SketchListState {
  const factory SketchListState.initial() = _Initial;
  const factory SketchListState.loading() = _Loading;
  const factory SketchListState.success({
    required List<Sketch> sketches,
  }) = _Success;
  const factory SketchListState.failure() = _Failure;
  const factory SketchListState.created({
    required Sketch sketch,
  }) = _Created;
}
