part of 'sketch_cubit.dart';

@freezed
class SketchState with _$SketchState {
  const factory SketchState.initial() = _Initial;
  const factory SketchState.success({
    required Sketch sketch,
    SketchLine? activeLine,
    @Default([]) List<SketchLine> redoList,
  }) = _Success;
  const factory SketchState.deleted({
    required Sketch sketch,
  }) = _Deleted;
}

extension SketchStateX on SketchState {
  bool get canUndo =>
      mapOrNull(success: (e) => e.sketch.lines.isNotEmpty) ?? false;
  bool get canRedo => mapOrNull(success: (e) => e.redoList.isNotEmpty) ?? false;
}
