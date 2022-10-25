// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/presentation/presentation.dart';

class _MockSketchService extends Mock implements SketchService {}

void main() {
  late SketchListCubit bloc;
  late SketchService service;

  group('constructor', () {
    setUp(() {
      service = _MockSketchService();
      when(() => service.onSketches)
          .thenAnswer((_) => Stream.value(<Sketch>[]));
      bloc = SketchListCubit();
    });
    test('initial', () {
      expect(bloc.state, SketchListState.initial());
    });

    blocTest<SketchListCubit, SketchListState>(
      'emits [success] when started() is called.',
      build: () => bloc,
      act: (bloc) => bloc.started(service),
      expect: () => [
        SketchListState.success(sketches: []),
      ],
    );
  });

  group('after constructor', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(
        id: '1',
        activeLayerId: 'layer1',
        layers: [SketchLayer(id: 'layer1')],
      );
      service = _MockSketchService();
      when(() => service.onSketches).thenAnswer((_) => Stream.value([]));
      bloc = SketchListCubit()..started(service);
    });
    blocTest<SketchListCubit, SketchListState>(
      'emits [created] when create() is called.',
      build: () => bloc,
      setUp: () {
        when(() => service.create(name: '')).thenAnswer((_) async => sketch);
      },
      act: (bloc) => bloc.create(),
      expect: () => [
        SketchListState.created(sketch: sketch),
      ],
      verify: (bloc) {
        verify(() => service.create(name: '')).called(1);
      },
    );

    blocTest<SketchListCubit, SketchListState>(
      'emits [] when delete() is called.',
      build: () => bloc,
      setUp: () {
        when(() => service.delete(sketch)).thenAnswer((_) async => sketch);
      },
      act: (bloc) => bloc.delete(sketch),
      expect: () => [],
      verify: (bloc) {
        verify(() => service.delete(sketch)).called(1);
      },
    );
  });
}
