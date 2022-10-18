import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
