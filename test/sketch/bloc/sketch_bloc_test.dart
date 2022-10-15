// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/sketch/cubit/sketch_cubit.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

class _MockSketchRepository extends Mock implements SketchRepository {}

class _FakeSketch extends Fake implements Sketch {}

void main() {
  late SketchRepository repository;
  late SketchCubit bloc;

  setUpAll(() {
    registerFallbackValue(_FakeSketch());
  });

  setUp(() {
    repository = _MockSketchRepository();
    bloc = SketchCubit(repository);
  });

  test('initial state', () {
    expect(bloc.state, SketchState.initial());
  });

  group('if sketch not exists', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(id: '1');
    });

    blocTest<SketchCubit, SketchState>(
      'emits [] when begin() ia called.',
      build: () => bloc,
      act: (bloc) => bloc.begin(Offset(0, 0), Size(1, 1)),
      expect: () => [],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when append() is called.',
      build: () => bloc,
      act: (bloc) => bloc.append(Offset(0, 0), Size(1, 1)),
      expect: () => [],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when init() is called.',
      build: () => bloc,
      act: (bloc) => bloc.init(sketch),
      expect: () => [
        SketchState.success(sketch: sketch),
      ],
    );
  });

  group('sketch save', () {
    setUp(() {
      when(() => repository.save(any())).thenAnswer((_) async => _FakeSketch());
    });

    tearDown(() {
      verify(() => repository.save(any())).called(1);
    });

    blocTest<SketchCubit, SketchState>(
      'emits [success] when begin() ia called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: Sketch(id: '1')),
      act: (bloc) => bloc.begin(Offset(0, 0), Size(1, 1)),
      expect: () => [
        SketchState.success(
            sketch: Sketch(
          id: '1',
          color: Colors.black,
          strokeWidth: 5.0,
          lines: [
            SketchLine(
              color: Colors.black,
              strokeWidth: 5.0,
              points: [Offset(0, 0)],
            ),
          ],
        )),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when begin() ia called. with orange, 2.5',
      build: () => bloc,
      seed: () => SketchState.success(
        sketch: Sketch(
          id: '1',
          color: Colors.orange,
          strokeWidth: 2.5,
        ),
      ),
      act: (bloc) => bloc.begin(Offset(0, 0), Size(1, 1)),
      expect: () => [
        SketchState.success(
            sketch: Sketch(
          id: '1',
          color: Colors.orange,
          strokeWidth: 2.5,
          lines: [
            SketchLine(
              color: Colors.orange,
              strokeWidth: 2.5,
              points: [Offset(0, 0)],
            ),
          ],
        )),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when append() is called.',
      build: () => bloc,
      seed: () => SketchState.success(
        sketch: Sketch(
          id: '1',
          lines: [
            SketchLine(),
          ],
        ),
      ),
      act: (bloc) => bloc.append(Offset(1, 0), Size(1, 1)),
      expect: () => [
        SketchState.success(
            sketch: Sketch(
          id: '1',
          color: Colors.black,
          strokeWidth: 5.0,
          lines: [
            SketchLine(
              color: Colors.black,
              strokeWidth: 5.0,
              points: [Offset(1, 0)],
            ),
          ],
        )),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when clear() is called.',
      build: () => bloc,
      seed: () =>
          SketchState.success(sketch: Sketch(id: '1', lines: [SketchLine()])),
      act: (bloc) => bloc.clear(),
      expect: () => [
        SketchState.success(sketch: Sketch(id: '1', lines: [])),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setColor() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: Sketch(id: '1')),
      act: (bloc) => bloc.setColor(Colors.red),
      expect: () => [
        SketchState.success(sketch: Sketch(id: '1', color: Colors.red)),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setStrokeWidth() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: Sketch(id: '1')),
      act: (bloc) => bloc.setStrokeWidth(9.0),
      expect: () => [
        SketchState.success(sketch: Sketch(id: '1', strokeWidth: 9.0)),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setTitle() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: Sketch(id: '1')),
      act: (bloc) => bloc.setTitle('test'),
      expect: () => [
        SketchState.success(sketch: Sketch(id: '1', title: 'test')),
      ],
    );
  });

  group('sketch delete', () {
    setUp(() {
      when(() => repository.delete(any())).thenAnswer((_) async => {});
    });

    tearDown(() {
      verify(() => repository.delete(any())).called(1);
    });

    blocTest<SketchCubit, SketchState>(
      'emits [deleted] when delete() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: Sketch(id: '1')),
      act: (bloc) => bloc.delete(),
      expect: () => [
        SketchState.deleted(sketch: Sketch(id: '1')),
      ],
    );
  });
}
