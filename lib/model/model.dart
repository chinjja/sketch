import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

import 'converter.dart';

part 'model.freezed.dart';
part 'model.g.dart';

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

  factory Sketch.fromJson(Map<String, dynamic> json) => _$SketchFromJson(json);
}

extension SketchX on Sketch {
  SketchLayer get activeLayer =>
      layers.firstWhere((element) => element.id == activeLayerId);

  Sketch addLayer(SketchLayer layer) {
    return copyWith(layers: [...layers, layer]);
  }

  Sketch removeLayer(SketchLayer layer) {
    return copyWith(layers: layers.where((e) => e.id != layer.id).toList());
  }

  Sketch setActiveLayer(SketchLayer layer) {
    if (layers.indexWhere((element) => element.id == layer.id) == -1) {
      throw Exception('$layer {layer.id} is not member');
    }
    return copyWith(activeLayerId: layer.id);
  }
}

@freezed
class SketchViewport with _$SketchViewport {
  const factory SketchViewport({
    @Default(0.0) double x,
    @Default(0.0) double y,
    required double width,
    required double height,
  }) = _SketchViewport;

  factory SketchViewport.fromJson(Map<String, dynamic> json) =>
      _$SketchViewportFromJson(json);
}

extension SketchViewportX on SketchViewport {
  Rect toRect() => Rect.fromLTWH(x, y, width, height);
  Offset get offset => Offset(x, y);
  Size get size => Size(width, height);

  SketchViewport moveTo(Offset offset) {
    return copyWith(x: offset.dx, y: offset.dy);
  }

  SketchViewport resize(Size size) {
    return copyWith(width: size.width, height: size.height);
  }
}

@freezed
class SketchLine with _$SketchLine {
  @OffsetConverter()
  const factory SketchLine({
    @Default([]) List<Offset> points,
    @Default(SketchPen()) SketchPen pen,
  }) = _SketchLine;

  factory SketchLine.fromJson(Map<String, dynamic> json) =>
      _$SketchLineFromJson(json);
}

extension SketchLineX on SketchLine {
  SketchLine addPoints(List<Offset> points) {
    return copyWith(points: [...this.points, ...points]);
  }

  bool isCollide(Offset p1, Offset p2) {
    final d1 = pen.strokeWidth / 2;
    final d2 = pow(d1, 2);
    final v12 = (p2 - p1).toVector();
    final v12t = Vector2(v12.y, -v12.x);

    for (int i = 0; i < points.length - 1; i++) {
      final p3 = points[i];
      final p4 = points[i + 1];

      final v31 = (p1 - p3).toVector();
      final v32 = (p2 - p3).toVector();

      if (v31.dot(v31).abs() < d2) return true;

      final v13 = (p3 - p1).toVector();
      final v14 = (p4 - p1).toVector();

      if (v12t.dot(v13).sign == v12t.dot(v14).sign) continue;

      final v34 = (p4 - p3).toVector();
      final v34t = Vector2(v34.y, -v34.x);

      if (v34t.dot(v31).sign != v34t.dot(v32).sign) return true;
    }
    return false;
  }
}

extension OffsetX on Offset {
  Vector2 toVector() => Vector2(dx, dy);
}

@freezed
class SketchPen with _$SketchPen {
  @ColorConverter()
  const factory SketchPen({
    @Default(Colors.black) Color color,
    @Default(5.0) double strokeWidth,
  }) = _SketchPen;

  factory SketchPen.fromJson(Map<String, dynamic> json) =>
      _$SketchPenFromJson(json);
}

@freezed
class SketchLayer with _$SketchLayer {
  const factory SketchLayer({
    required String id,
    @Default(true) bool visible,
    @Default('') String title,
    @Default([]) List<SketchLine> lines,
  }) = _SketchLayer;

  factory SketchLayer.fromJson(Map<String, dynamic> json) =>
      _$SketchLayerFromJson(json);
}

extension SketchLayerX on SketchLayer {
  SketchLayer addLine(SketchLine line) {
    return copyWith(lines: [...lines, line]);
  }
}
