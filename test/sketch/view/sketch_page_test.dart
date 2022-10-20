// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/sketch/cubit/sketch_cubit.dart';
import 'package:sketch/sketch/view/sketch_page.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

class _MockSketchCubit extends MockCubit<SketchState> implements SketchCubit {}

class _FakeColor extends Fake implements Color {}

class _FakeOffset extends Fake implements Offset {}

class _FakeSize extends Fake implements Size {}

void main() {
  final clearButtonKey = Key('SketchView_ClearButton');
  final strokeWidthSliderKey = Key('SketchView_StrokeWidthSlider');
  final colorPickerKey = Key('SketchView_ColorPicker');

  late SketchCubit bloc;

  setUpAll(() {
    registerFallbackValue(_FakeColor());
    registerFallbackValue(_FakeOffset());
    registerFallbackValue(_FakeSize());
  });

  setUp(() {
    bloc = _MockSketchCubit();
  });

  group('render test', () {
    testWidgets('render loading', (tester) async {
      when(() => bloc.state).thenReturn(SketchState.initial());

      await tester.pumpApp(bloc);

      expect(find.byType(SketchCanvasView), findsNothing);

      expect(find.byKey(colorPickerKey), findsOneWidget);
      expect(find.byKey(strokeWidthSliderKey), findsOneWidget);
      expect(find.byKey(clearButtonKey), findsOneWidget);
    });
    testWidgets('render sketch contents', (tester) async {
      when(() => bloc.state).thenReturn(
          SketchState.success(sketch: Sketch.create('1', title: 'test-title')));

      await tester.pumpApp(bloc);

      expect(find.byType(SketchCanvasView), findsOneWidget);
      expect(find.text('test-title'), findsOneWidget);

      expect(find.byKey(colorPickerKey), findsOneWidget);
      expect(find.byKey(strokeWidthSliderKey), findsOneWidget);
      expect(find.byKey(clearButtonKey), findsOneWidget);
    });
  });

  group('control test', () {
    setUp(() {
      when(() => bloc.state)
          .thenReturn(SketchState.success(sketch: Sketch.create('1')));
    });

    testWidgets('clear()', (tester) async {
      when(() => bloc.clear()).thenReturn(null);

      await tester.pumpApp(bloc);
      await tester.tap(find.byKey(clearButtonKey));

      verify(() => bloc.clear()).called(1);
    });

    testWidgets('strokeWidth()', (tester) async {
      when(() => bloc.setStrokeWidth(any())).thenReturn(null);

      await tester.pumpApp(bloc);
      await tester.drag(find.byKey(strokeWidthSliderKey), Offset(50, 0));

      verify(() => bloc.setStrokeWidth(any())).called(greaterThan(0));
    });

    testWidgets('color()', (tester) async {
      await tester.pumpApp(bloc);
      await tester.tap(find.byKey(colorPickerKey));
      await tester.pumpAndSettle();
      expect(find.byType(BlockPicker), findsOneWidget);
    });

    testWidgets('line()', (tester) async {
      when(() => bloc.begin(any(), any())).thenReturn(null);
      when(() => bloc.append(any())).thenReturn(null);
      await tester.pumpApp(bloc);

      await tester.drag(find.byType(SketchCanvasView), Offset(50, 0));

      verify(() => bloc.begin(any(), any())).called(1);
      verify(() => bloc.append(any())).called(greaterThan(0));
      verify(() => bloc.end()).called(1);
    });

    testWidgets('point()', (tester) async {
      when(() => bloc.begin(any(), any())).thenReturn(null);
      when(() => bloc.append(any())).thenReturn(null);
      await tester.pumpApp(bloc);

      await tester.tap(find.byType(SketchCanvasView));

      verify(() => bloc.begin(any(), any())).called(1);
      verify(() => bloc.end()).called(1);
    });

    testWidgets('undo()', (tester) async {
      await tester.pumpApp(bloc);
      await tester.tap(find.byIcon(Icons.undo));

      verifyNever(() => bloc.undo());
    });

    testWidgets('redo()', (tester) async {
      await tester.pumpApp(bloc);
      await tester.tap(find.byIcon(Icons.redo));

      verifyNever(() => bloc.redo());
    });

    // testWidgets('undo2()', (tester) async {
    //   when(() => bloc.state).thenReturn(
    //     SketchState.success(
    //       sketch: Sketch(
    //         id: '1',
    //         lines: [SketchLine()],
    //       ),
    //     ),
    //   );
    //   await tester.pumpApp(bloc);
    //   await tester.tap(find.byIcon(Icons.undo));

    //   verify(() => bloc.undo()).called(1);
    // });

    // testWidgets('redo2()', (tester) async {
    //   when(() => bloc.state).thenReturn(
    //     SketchState.success(
    //       redoList: [SketchLine()],
    //       sketch: Sketch(id: '1'),
    //     ),
    //   );
    //   await tester.pumpApp(bloc);
    //   await tester.tap(find.byIcon(Icons.redo));

    //   verify(() => bloc.redo()).called(1);
    // });
  });
}

extension WidgetTesterX on WidgetTester {
  Future pumpApp(SketchCubit bloc, [Widget? widget]) async {
    await pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(home: widget ?? SketchView()),
    ));
  }
}
