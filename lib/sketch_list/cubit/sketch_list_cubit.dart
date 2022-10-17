import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

part 'sketch_list_state.dart';
part 'sketch_list_cubit.freezed.dart';

class SketchListCubit extends Cubit<SketchListState> {
  SketchRepository? _repo;
  StreamSubscription? subscription;

  SketchListCubit() : super(const SketchListState.initial());

  @override
  Future<void> close() {
    subscription?.cancel();
    return super.close();
  }

  void started(SketchRepository repository) {
    assert(_repo == null);
    _repo = repository;
    subscription = repository.onSketches.listen((event) {
      emit(state.maybeMap(
        success: (e) => e.copyWith(sketches: event),
        orElse: () => SketchListState.success(sketches: event),
      ));
    });
  }

  void create() async {
    final sketch = await _repo!.create(name: '');
    emit(SketchListState.created(sketch: sketch));
  }

  void delete(Sketch sketch) async {
    await _repo!.delete(sketch);
  }
}
