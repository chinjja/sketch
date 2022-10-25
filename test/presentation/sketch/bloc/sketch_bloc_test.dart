// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/presentation/presentation.dart';

class _MockSketchService extends Mock implements SketchService {}

class _FakeSketch extends Fake implements Sketch {}

void main() {
  late SketchService service;
  late SketchCubit bloc;

  setUpAll(() {
    registerFallbackValue(_FakeSketch());
  });

  setUp(() {
    service = _MockSketchService();
    bloc = SketchCubit();
  });

  blocTest<SketchCubit, SketchState>(
    'emits [] when started() ia called.',
    build: () => bloc,
    act: (bloc) => bloc.started(service),
    expect: () => [],
  );

  test('initial state', () {
    expect(bloc.state, SketchState.initial());
  });

  group('if sketch not exists', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(
        id: '1',
        activeLayerId: 'layer1',
        layers: [SketchLayer(id: 'layer1')],
      );
      bloc.started(service);
    });

    blocTest<SketchCubit, SketchState>(
      'emits [] when begin() ia called.',
      build: () => bloc,
      act: (bloc) => bloc.begin(1, Offset(0, 0), Size(100, 100)),
      expect: () => [],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when append() is called.',
      build: () => bloc,
      act: (bloc) => bloc.append(Offset(0, 0)),
      expect: () => [],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when sketch() is called.',
      build: () => bloc,
      act: (bloc) => bloc.sketch(sketch),
      expect: () => [
        SketchState.success(sketch: sketch),
      ],
    );
    blocTest<SketchCubit, SketchState>(
      'emits [] when undo is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.undo(),
      expect: () => [],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when redo is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.redo(),
      expect: () => [],
    );
  });

  group('sketch never save', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch.create('1');
      bloc.started(service);
    });

    tearDown(() {
      verifyNever(() => service.save(any()));
    });
    blocTest<SketchCubit, SketchState>(
      'emits [success] when begin() ia called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.begin(1, Offset(0, 0), Size(100, 100)),
      expect: () => [
        SketchState.success(
          activeLine: SketchLine(
            pen: sketch.pen,
            points: [Offset(0, 0)],
          ),
          sketch: sketch.copyWith(
            viewport: SketchViewport(width: 100, height: 100),
          ),
        ),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when append() is called.',
      build: () => bloc,
      seed: () => SketchState.success(
        sketch: sketch,
      ),
      act: (bloc) => bloc.append(Offset(1, 0)),
      expect: () => [],
    );
    blocTest<SketchCubit, SketchState>(
      'emits [success] when append() is called.',
      build: () => bloc,
      seed: () => SketchState.success(
        activeLine: SketchLine(),
        sketch: sketch,
      ),
      act: (bloc) => bloc.append(Offset(1, 0)),
      expect: () => [
        SketchState.success(
          activeLine: SketchLine(
            pen: sketch.pen,
            points: [Offset(1, 0)],
          ),
          sketch: sketch,
        ),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when end() is called.',
      build: () => bloc,
      seed: () => SketchState.success(
        sketch: sketch,
      ),
      act: (bloc) => bloc.end(),
      expect: () => [],
    );
  });

  group('sketch save', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(
        id: '1',
        activeLayerId: 'layer1',
        layers: [SketchLayer(id: 'layer1')],
      );
      when(() => service.save(any())).thenAnswer((_) async => _FakeSketch());
      bloc.started(service);
    });

    tearDown(() {
      verify(() => service.save(any())).called(1);
    });

    // blocTest<SketchCubit, SketchState>(
    //   'emits [success] when clear() is called.',
    //   build: () => bloc,
    //   seed: () => SketchState.success(
    //       sketch: Sketch.create('1', layer: SketchLayer(id: 'a'))),
    //   act: (bloc) => bloc.clear(),
    //   expect: () => [
    //     SketchState.success(
    //         sketch: Sketch.create('1', layer: SketchLayer(id: 'a'))),
    //   ],
    // );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setColor() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.setColor(Colors.red),
      expect: () => [
        SketchState.success(sketch: sketch.copyWith.pen(color: Colors.red)),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setStrokeWidth() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.setStrokeWidth(9.0),
      expect: () => [
        SketchState.success(sketch: sketch.copyWith.pen(strokeWidth: 9.0)),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when setTitle() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.setTitle('test'),
      expect: () => [
        SketchState.success(sketch: sketch.copyWith(title: 'test')),
      ],
    );

    // blocTest<SketchCubit, SketchState>(
    //   'emits [success] when undo is called.',
    //   build: () => bloc,
    //   seed: () => SketchState.success(
    //     sketch: Sketch(
    //       id: '1',
    //       lines: [
    //         SketchLine(),
    //       ],
    //     ),
    //   ),
    //   act: (bloc) => bloc.undo(),
    //   expect: () => [
    //     SketchState.success(
    //       sketch: Sketch(
    //         id: '1',
    //       ),
    //       redoList: [
    //         SketchLine(),
    //       ],
    //     ),
    //   ],
    // );

    // blocTest<SketchCubit, SketchState>(
    //   'emits [success] when redo is called.',
    //   build: () => bloc,
    //   seed: () => SketchState.success(
    //     redoList: [
    //       SketchLine(),
    //     ],
    //     sketch: Sketch(
    //       id: '1',
    //     ),
    //   ),
    //   act: (bloc) => bloc.redo(),
    //   expect: () => [
    //     SketchState.success(
    //       sketch: Sketch(
    //         id: '1',
    //         lines: [
    //           SketchLine(),
    //         ],
    //       ),
    //     ),
    //   ],
    // );
    blocTest<SketchCubit, SketchState>(
      'emits [success] when end() is called. line has a point',
      build: () => bloc,
      seed: () => SketchState.success(
        activeLine: SketchLine(points: [Offset.zero]),
        sketch: sketch,
      ),
      act: (bloc) => bloc.end(),
      expect: () => [
        SketchState.success(
          canUndo: true,
          canRedo: false,
          activeLine: null,
          sketch: sketch.copyWith(layers: [
            sketch.activeLayer.copyWith(lines: [
              SketchLine(points: [Offset.zero, Offset.zero])
            ]),
          ]),
        ),
      ],
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when end() is called. line have points greater than one',
      build: () => bloc,
      seed: () => SketchState.success(
        activeLine: SketchLine(points: [Offset.zero, Offset.zero]),
        sketch: sketch,
      ),
      act: (bloc) => bloc.end(),
      expect: () => [
        SketchState.success(
          canUndo: true,
          canRedo: false,
          activeLine: null,
          sketch: sketch.copyWith(layers: [
            sketch.activeLayer.copyWith(lines: [
              SketchLine(points: [Offset.zero, Offset.zero])
            ]),
          ]),
        ),
      ],
    );
  });

  group('sketch delete', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch.create('1');
      when(() => service.delete(any())).thenAnswer((_) async => {});
      bloc.started(service);
    });

    tearDown(() {
      verify(() => service.delete(any())).called(1);
    });

    blocTest<SketchCubit, SketchState>(
      'emits [deleted] when delete() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.delete(),
      expect: () => [
        SketchState.deleted(sketch: sketch),
      ],
    );
  });
}
