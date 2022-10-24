import 'dart:convert';
import 'dart:developer';

import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../sketch_repository.dart';

class SketchRepository {
  final _sketches = BehaviorSubject.seeded(const <Sketch>[]);
  final SharedPreferences _sharedPreference;

  SketchRepository(this._sharedPreference) {
    _loadAll();
  }

  late final Stream<List<Sketch>> onSketches = _sketches.stream;

  Future<Sketch> create({String? id, required String name}) async {
    final list = await _sketches.first;
    final layer = SketchLayer(id: const Uuid().v4());
    final sketch = Sketch(
      id: id ?? const Uuid().v4(),
      title: name,
      activeLayerId: layer.id,
      layers: [layer],
    );
    _sketches.add([...list, sketch]);
    await _save(sketch);
    return sketch;
  }

  Future<void> delete(Sketch sketch) async {
    final list = await _sketches.first;
    _sketches.add([...list.where((e) => e.id != sketch.id)]);
    await _delete(sketch);
  }

  Future<Sketch> save(Sketch sketch) async {
    final list = await _sketches.first;
    _sketches.add([...list.map((e) => e.id != sketch.id ? e : sketch)]);
    await _save(sketch);
    return sketch;
  }

  Future<Sketch?> get(String id) async {
    final list = await _sketches.first;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    return list[idx];
  }

  Future _loadAll() async {
    final list = _sharedPreference.getStringList('sketch_ids') ?? [];
    List<Sketch> sketches = [];

    for (final id in list) {
      final sketch = await _load(id);
      if (sketch != null) {
        sketches.add(sketch);
      }
    }
    _sketches.add(sketches);
  }

  Future<Sketch?> _load(String id) async {
    final data = _sharedPreference.getString(id);

    try {
      if (data != null) {
        return Sketch.fromJson(jsonDecode(data));
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  Future<void> _save(Sketch sketch) async {
    await _updateIds();
    await _sharedPreference.setString(sketch.id, jsonEncode(sketch.toJson()));
  }

  Future<void> _delete(Sketch sketch) async {
    await _updateIds();
    await _sharedPreference.remove(sketch.id);
  }

  Future<void> _updateIds() async {
    final list = _sketches.value.map((e) => e.id).toList();
    await _sharedPreference.setStringList('sketch_ids', list);
  }
}
