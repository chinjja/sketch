import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

part 'sketch_list_state.dart';
part 'sketch_list_cubit.freezed.dart';

class SketchListCubit extends Cubit<SketchListState> {
  final SketchRepository _repo;
  late final StreamSubscription subscription;
  SketchListCubit(this._repo) : super(const SketchListState.initial()) {
    subscription = _repo.onSketches.listen((event) {
      emit(state.maybeMap(
        success: (e) => e.copyWith(sketches: event),
        orElse: () => SketchListState.success(sketches: event),
      ));
    });
  }

  void create() async {
    final sketch = await _repo.create(name: '');
    emit(SketchListState.created(sketch: sketch));
  }

  void delete(Sketch sketch) {
    _repo.delete(sketch);
  }
}
