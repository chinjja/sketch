import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

import '../sketch_repository.dart';

class SketchRepository {
  final _sketches = BehaviorSubject.seeded(const <Sketch>[]);

  late final onSketches = _sketches.stream;

  Future<Sketch> create({String? id, required String name}) async {
    final list = await _sketches.first;
    final sketch = Sketch(
      id: id ?? const Uuid().v4(),
      title: name,
    );
    _sketches.add([...list, sketch]);
    return sketch;
  }

  Future<void> delete(Sketch sketch) async {
    final list = await _sketches.first;
    _sketches.add([...list.where((e) => e.id != sketch.id)]);
  }

  Future<Sketch> save(Sketch sketch) async {
    final list = await _sketches.first;
    _sketches.add([...list.map((e) => e.id != sketch.id ? e : sketch)]);
    return sketch;
  }

  Future<Sketch?> get(String id) async {
    final list = await _sketches.first;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    return list[idx];
  }
}
