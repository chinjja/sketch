// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/sketch_list/cubit/sketch_list_cubit.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

class _MockSketchRepository extends Mock implements SketchRepository {}

void main() {
  late SketchListCubit bloc;
  late SketchRepository repository;

  group('constructor', () {
    setUp(() {
      repository = _MockSketchRepository();
      when(() => repository.onSketches)
          .thenAnswer((_) => Stream.value(<Sketch>[]));
      bloc = SketchListCubit();
    });
    test('initial', () {
      expect(bloc.state, SketchListState.initial());
    });

    blocTest<SketchListCubit, SketchListState>(
      'emits [success] when started() is called.',
      build: () => bloc,
      act: (bloc) => bloc.started(repository),
      expect: () => [
        SketchListState.success(sketches: []),
      ],
    );
  });

  group('after constructor', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(id: '1');
      repository = _MockSketchRepository();
      when(() => repository.onSketches).thenAnswer((_) => Stream.value([]));
      bloc = SketchListCubit()..started(repository);
    });
    blocTest<SketchListCubit, SketchListState>(
      'emits [created] when create() is called.',
      build: () => bloc,
      setUp: () {
        when(() => repository.create(name: '')).thenAnswer((_) async => sketch);
      },
      act: (bloc) => bloc.create(),
      expect: () => [
        SketchListState.created(sketch: sketch),
      ],
      verify: (bloc) {
        verify(() => repository.create(name: '')).called(1);
      },
    );

    blocTest<SketchListCubit, SketchListState>(
      'emits [] when delete() is called.',
      build: () => bloc,
      setUp: () {
        when(() => repository.delete(sketch)).thenAnswer((_) async => sketch);
      },
      act: (bloc) => bloc.delete(sketch),
      expect: () => [],
      verify: (bloc) {
        verify(() => repository.delete(sketch)).called(1);
      },
    );
  });
}
