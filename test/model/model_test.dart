// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/model/model.dart';

void main() {
  group('Sketch', () {
    test('addLayer()', () {
      final sketch = Sketch(
        id: '1',
        activeLayerId: 'a',
        layers: [],
      );
      expect(
        sketch.addLayer(SketchLayer(id: 'a')),
        Sketch(
          id: '1',
          activeLayerId: 'a',
          layers: [
            SketchLayer(id: 'a'),
          ],
        ),
      );
    });

    test('removeLayer()', () {
      final sketch = Sketch(
        id: '1',
        activeLayerId: 'a',
        layers: [SketchLayer(id: 'a')],
      );
      expect(
        sketch.removeLayer(SketchLayer(id: 'a')),
        Sketch(
          id: '1',
          activeLayerId: 'a',
          layers: [],
        ),
      );
    });

    test('when layer is not member then setActiveLayer() should fail', () {
      final sketch = Sketch(
        id: '1',
        activeLayerId: 'a',
        layers: [SketchLayer(id: 'a')],
      );

      expect(
        () => sketch.setActiveLayer(SketchLayer(id: 'b')),
        throwsA(
          isA<Exception>(),
        ),
      );
    });

    test('setActiveLayer()', () {
      final sketch = Sketch(
        id: '1',
        activeLayerId: 'a',
        layers: [
          SketchLayer(id: 'a'),
          SketchLayer(id: 'b'),
        ],
      );

      expect(
        sketch.setActiveLayer(SketchLayer(id: 'b')),
        Sketch(
          id: '1',
          activeLayerId: 'b',
          layers: [
            SketchLayer(id: 'a'),
            SketchLayer(id: 'b'),
          ],
        ),
      );
    });
  });

  group('SketchViewport', () {
    test('moveTo', () {
      final viewport = SketchViewport(x: 1, y: 1, width: 1, height: 1);

      expect(
          viewport.moveTo(Offset(2, 3)),
          SketchViewport(
            x: 2,
            y: 3,
            width: 1,
            height: 1,
          ));
    });
    test('resize()', () {
      final viewport = SketchViewport(x: 1, y: 1, width: 1, height: 1);

      expect(
          viewport.resize(Size(2, 3)),
          SketchViewport(
            x: 1,
            y: 1,
            width: 2,
            height: 3,
          ));
    });
  });

  group('SketchLine', () {
    test('addPoints()', () {
      final line = SketchLine();

      expect(
        line.addPoints([
          Offset(0, 1),
        ]),
        SketchLine(
          points: [
            Offset(0, 1),
          ],
        ),
      );
    });
  });

  test('isCollide()', () {
    final line = SketchLine(points: [
      Offset(0, 0),
      Offset(100, 100),
    ]);
    expect(
      line.isCollide(Offset(0, 10), Offset(50, 10)),
      true,
    );
    expect(
      line.isCollide(Offset(0, 10), Offset(-50, 10)),
      false,
    );
  });
}
