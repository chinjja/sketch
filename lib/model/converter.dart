import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class ColorConverter extends JsonConverter<Color, int> {
  const ColorConverter();
  @override
  Color fromJson(int json) {
    return Color(json);
  }

  @override
  int toJson(Color object) {
    return object.value;
  }
}

class OffsetConverter extends JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();
  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(json['x'], json['y']);
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {
      'x': object.dx,
      'y': object.dy,
    };
  }
}

class SizeConverter extends JsonConverter<Size, Map<String, dynamic>> {
  const SizeConverter();
  @override
  Size fromJson(Map<String, dynamic> json) {
    return Size(json['width'], json['height']);
  }

  @override
  Map<String, dynamic> toJson(Size object) {
    return {
      'width': object.width,
      'height': object.height,
    };
  }
}
