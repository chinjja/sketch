import 'dart:convert';

import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/model/model.dart';

class SharedPreferenceSketchRepository implements SketchRepository {
  final BehaviorSubject<List<Sketch>> _sketches;
  final SharedPreferences _sharedPreferences;

  SharedPreferenceSketchRepository(this._sharedPreferences,
      [BehaviorSubject<List<Sketch>>? subject])
      : _sketches = subject ?? BehaviorSubject.seeded(const []);

  @override
  Future<void> init() async {
    final data = await fetchAll();
    _sketches.add(data);
  }

  @override
  Future<void> delete(Sketch sketch) async {
    await deleteById(sketch.id);
  }

  @override
  Future<void> deleteById(String id) async {
    final list = _sharedPreferences.getStringList('sketch_ids') ?? [];
    await _sharedPreferences.setStringList(
      'sketch_ids',
      list.where((e) => e != id).toList(),
    );
    await _sharedPreferences.remove(id);
    _sketches.add(_sketches.value.where((e) => e.id != id).toList());
  }

  @override
  Future<List<Sketch>> fetchAll() async {
    final list = _sharedPreferences.getStringList('sketch_ids') ?? [];
    List<Sketch> sketches = [];

    for (final id in list) {
      final sketch = await fetchById(id);
      if (sketch != null) {
        sketches.add(sketch);
      }
    }
    return sketches;
  }

  @override
  Future<Sketch?> fetchById(String id) async {
    final data = _sharedPreferences.getString(id);
    if (data == null) return null;
    return Sketch.fromJson(jsonDecode(data));
  }

  @override
  Future<Sketch> save(Sketch sketch) async {
    final data = _sharedPreferences.getString(sketch.id);
    if (data == null) {
      final list = _sharedPreferences.getStringList('sketch_ids') ?? [];
      await _sharedPreferences
          .setStringList('sketch_ids', [...list, sketch.id]);
    }
    await _sharedPreferences.setString(sketch.id, jsonEncode(sketch.toJson()));
    if (data == null) {
      _sketches.add([..._sketches.value, sketch]);
    } else {
      _sketches.add(
        _sketches.value
            .map((element) => element.id == sketch.id ? sketch : element)
            .toList(),
      );
    }
    return sketch;
  }

  @override
  Stream<List<Sketch>> watchAll() {
    return _sketches;
  }
}
