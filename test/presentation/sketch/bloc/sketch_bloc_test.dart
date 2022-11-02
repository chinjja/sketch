// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/presentation/presentation.dart';
import 'package:sketch/utils/utils.dart';

class _MockSketchService extends Mock implements SketchService {}

class _FakeSketch extends Fake implements Sketch {}

class _MockUndoStack extends Mock implements UndoStack<Sketch?> {}

void main() {
  late UndoStack<Sketch?> stack;
  late SketchService service;
  late SketchCubit bloc;

  setUpAll(() {
    registerFallbackValue(_FakeSketch());
  });

  setUp(() {
    stack = _MockUndoStack();
    service = _MockSketchService();
    bloc = SketchCubit(stack);
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
      when(() => stack.canRedo).thenReturn(false);
      when(() => stack.canUndo).thenReturn(false);
      when(() => stack.state).thenReturn(sketch);
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
  });

  group('when close() save a sketch', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch(
        id: '1',
        activeLayerId: 'layer1',
        layers: [SketchLayer(id: 'layer1')],
      );
      when(() => service.save(any())).thenAnswer((_) async => sketch);
      bloc.started(service);
      when(() => stack.canRedo).thenReturn(false);
      when(() => stack.canUndo).thenReturn(false);
      when(() => stack.state).thenReturn(sketch);
    });

    tearDown(() {
      verify(() => service.save(any())).called(1);
    });
    blocTest<SketchCubit, SketchState>(
      'emits [success] when sketch() is called.',
      build: () => bloc,
      setUp: () {
        when(() => service.getById(sketch.id)).thenAnswer((_) async => sketch);
        when(() => stack.reset(sketch)).thenReturn(null);
      },
      act: (bloc) => bloc.sketch(sketch.id),
      expect: () => [
        SketchState.loading(),
        SketchState.success(sketch: sketch),
      ],
      verify: (bloc) {
        verify(() => service.getById(sketch.id)).called(1);
        verify(() => stack.reset(sketch)).called(1);
      },
    );
    blocTest<SketchCubit, SketchState>(
      'emits [] when undo is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.undo(),
      expect: () => [],
      verify: (bloc) {
        verifyNever(() => stack.undo());
      },
    );

    blocTest<SketchCubit, SketchState>(
      'emits [] when redo is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch),
      act: (bloc) => bloc.redo(),
      expect: () => [],
      verify: (bloc) {
        verifyNever(() => stack.redo());
      },
    );
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

    blocTest<SketchCubit, SketchState>(
      'emits [success] when clear() is called.',
      build: () => bloc,
      seed: () => SketchState.success(sketch: sketch, activeLine: SketchLine()),
      act: (bloc) => bloc.clear(),
      expect: () => [
        SketchState.success(
          sketch: sketch,
        ),
      ],
    );

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
      when(() => stack.canRedo).thenReturn(false);
      when(() => stack.canUndo).thenReturn(false);
      when(() => stack.state).thenReturn(sketch);
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

  group('undo stack', () {
    late Sketch sketch;
    late Sketch stackState;
    setUp(() {
      sketch = Sketch.create('1');
      stackState = Sketch.create('2');
      bloc.started(service);
      when(() => service.save(any())).thenAnswer((_) async => sketch);
    });

    tearDown(() {
      verify(() => service.save(any())).called(1);
    });

    blocTest<SketchCubit, SketchState>(
      'emits [success] when undo is called.',
      build: () => bloc,
      setUp: () {
        when(() => stack.canRedo).thenReturn(false);
        when(() => stack.canUndo).thenReturn(true);
        when(() => stack.state).thenReturn(stackState);
      },
      seed: () => SketchState.success(
        sketch: sketch,
      ),
      act: (bloc) => bloc.undo(),
      expect: () => [
        SketchState.success(
          canRedo: false,
          canUndo: true,
          sketch: stackState,
        ),
      ],
      verify: (bloc) {
        verify(() => stack.undo()).called(1);
      },
    );

    blocTest<SketchCubit, SketchState>(
      'emits [success] when redo is called.',
      build: () => bloc,
      setUp: () {
        when(() => stack.canRedo).thenReturn(true);
        when(() => stack.canUndo).thenReturn(false);
        when(() => stack.state).thenReturn(stackState);
      },
      seed: () => SketchState.success(
        sketch: sketch,
      ),
      act: (bloc) => bloc.redo(),
      expect: () => [
        SketchState.success(
          canRedo: true,
          canUndo: false,
          sketch: stackState,
        ),
      ],
      verify: (bloc) {
        verify(() => stack.redo()).called(1);
      },
    );
  });
}
