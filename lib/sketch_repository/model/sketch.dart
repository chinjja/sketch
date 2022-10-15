import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/converter.dart';

part 'sketch.freezed.dart';
part 'sketch.g.dart';

@freezed
class Sketch with _$Sketch {
  @ColorConverter()
  const factory Sketch({
    required String id,
    @Default('') String title,
    @Default([]) List<SketchLine> lines,
    @Default(Colors.black) Color color,
    @Default(5.0) double strokeWidth,
  }) = _Sketch;

  factory Sketch.fromJson(Map<String, dynamic> json) => _$SketchFromJson(json);
}

@freezed
class SketchLine with _$SketchLine {
  @OffsetConverter()
  @ColorConverter()
  const factory SketchLine({
    @Default([]) List<Offset> points,
    @Default(Colors.black) Color color,
    @Default(5.0) double strokeWidth,
  }) = _SketchLine;

  factory SketchLine.fromJson(Map<String, dynamic> json) =>
      _$SketchLineFromJson(json);
}
