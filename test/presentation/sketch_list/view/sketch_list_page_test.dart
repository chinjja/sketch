// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/presentation/presentation.dart';

class _MockSketchListCubit extends MockCubit<SketchListState>
    implements SketchListCubit {}

void main() {
  late SketchListCubit bloc;

  setUp(() {
    bloc = _MockSketchListCubit();
  });
  group('render', () {
    testWidgets('when initial() sketch then show loading', (tester) async {
      when(() => bloc.state).thenReturn(SketchListState.initial());
      await tester.pumpApp(bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SketchItemView), findsNothing);
    });
    testWidgets('when success([]) then show empty message', (tester) async {
      when(() => bloc.state).thenReturn(SketchListState.success(sketches: []));
      await tester.pumpApp(bloc);

      expect(find.text('Empty'), findsOneWidget);
      expect(find.byType(SketchItemView), findsNothing);
    });
    testWidgets('when success([#sketch1]) then show empty message',
        (tester) async {
      when(() => bloc.state).thenReturn(SketchListState.success(sketches: [
        Sketch.create('1', title: '#sketch1'),
      ]));
      await tester.pumpApp(bloc);

      expect(find.text('#sketch1'), findsOneWidget);
      expect(find.byType(SketchItemView), findsOneWidget);
    });
  });

  group('control', () {
    testWidgets('tap create button', (tester) async {
      when(() => bloc.state).thenReturn(SketchListState.success(sketches: []));

      await tester.pumpApp(bloc);
      await tester.tap(find.byIcon(Icons.add));

      verify(() => bloc.create()).called(1);
    });

    testWidgets('tap delete button', (tester) async {
      final sketch = Sketch.create('1', title: '#sketch1');
      when(() => bloc.state).thenReturn(SketchListState.success(sketches: [
        sketch,
      ]));
      await tester.pumpApp(bloc);
      expect(find.byType(SketchItemView), findsOneWidget);
      await tester.fling(find.byType(SketchItemView), Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      verify(() => bloc.delete(sketch)).called(1);
    });
  });
}

extension _WidgetTesterX on WidgetTester {
  Future pumpApp(SketchListCubit bloc) async {
    await pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: SketchListView(),
        ),
      ),
    );
  }
}
