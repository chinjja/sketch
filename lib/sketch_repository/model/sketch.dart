import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

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
