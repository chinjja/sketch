import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sketch/presentation/presentation.dart';

part 'sketch_list_state.dart';
part 'sketch_list_cubit.freezed.dart';

class SketchListCubit extends Cubit<SketchListState> {
  SketchService? _service;
  StreamSubscription? subscription;

  SketchListCubit() : super(const SketchListState.initial());

  @override
  Future<void> close() {
    subscription?.cancel();
    return super.close();
  }

  void started(SketchService service) {
    assert(_service == null);
    _service = service;
    subscription = service.onSketches.listen((event) {
      emit(state.maybeMap(
        success: (e) => e.copyWith(sketches: event),
        orElse: () => SketchListState.success(sketches: event),
      ));
    });
  }

  void create() async {
    final sketch = await _service!.create(name: '');
    emit(SketchListState.created(sketch: sketch));
  }

  void delete(Sketch sketch) async {
    await _service!.delete(sketch);
  }
}
