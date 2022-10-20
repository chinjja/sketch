import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import '../converter/converter.dart';

part 'sketch.freezed.dart';

@freezed
class Sketch with _$Sketch {
  const factory Sketch({
    required String id,
    @Default('') String title,
    @Default(SketchViewport(width: 400, height: 400)) SketchViewport viewport,
    @Default(SketchPen()) SketchPen pen,
    required String activeLayerId,
    required List<SketchLayer> layers,
  }) = _Sketch;

  factory Sketch.create(String id, {String? title, SketchLayer? layer}) {
    layer ??= SketchLayer(id: const Uuid().v4());
    return Sketch(
      id: id,
      title: title ?? '',
      activeLayerId: layer.id,
      layers: [layer],
    );
  }
}

extension SketchX on Sketch {
  SketchLayer get activeLayer =>
      layers.firstWhere((element) => element.id == activeLayerId);
}

@freezed
class SketchViewport with _$SketchViewport {
  const factory SketchViewport({
    @Default(0.0) double x,
    @Default(0.0) double y,
    required double width,
    required double height,
  }) = _SketchViewport;
}

extension SketchViewportX on SketchViewport {
  Rect toRect() => Rect.fromLTWH(x, y, width, height);
}

@freezed
class SketchLine with _$SketchLine {
  @OffsetConverter()
  const factory SketchLine({
    @Default([]) List<Offset> points,
    @Default(SketchPen()) SketchPen pen,
  }) = _SketchLine;
}

extension SketchLineX on SketchLine {
  bool isCollide(Offset point) {
    final p3 = Vector2(point.dx, point.dy);
    final d1 = pen.strokeWidth / 2;
    final d2 = pow(d1, 2);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Vector2(points[i].dx, points[i].dy);
      final p2 = Vector2(points[i + 1].dx, points[i + 1].dy);

      final v12 = p2 - p1;
      final v13 = p3 - p1;
      final v23 = p3 - p2;

      if (v13.dot(v13).abs() < d2) return true;
      if (v23.dot(v23).abs() < d2) return true;

      if (v12.dot(v12).abs() < 1e-7) continue;
      final n12 = v12.normalized();
      final n13 = v13.normalized();
      final n23 = v23.normalized();

      if (n12.dot(n13) < 0 || n12.dot(n23) > 0) continue;

      final n = Vector2(n12.y, -n12.x);
      if (n.dot(v13).abs() < d1) return true;
    }
    return false;
  }
}

@freezed
class SketchPen with _$SketchPen {
  @ColorConverter()
  const factory SketchPen({
    @Default(Colors.black) color,
    @Default(5.0) double strokeWidth,
  }) = _SketchPen;
}

@freezed
class SketchLayer with _$SketchLayer {
  const factory SketchLayer({
    required String id,
    @Default(true) bool visible,
    @Default('') String title,
    @Default([]) List<SketchLine> lines,
  }) = _SketchLayer;
}
