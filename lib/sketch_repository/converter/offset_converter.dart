import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
