import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/model/model.dart';
import 'package:uuid/uuid.dart';

class SketchService {
  final SketchRepository _repository;

  SketchService(this._repository);

  late Stream<List<Sketch>> onSketches = _repository.watchAll();

  Future<Sketch> create({String? id, String? name}) async {
    final layer = SketchLayer(id: const Uuid().v4());
    final sketch = Sketch(
      id: id ?? const Uuid().v4(),
      title: name ?? '',
      activeLayerId: layer.id,
      layers: [layer],
    );
    await save(sketch);
    return sketch;
  }

  Future<void> delete(Sketch sketch) async {
    await _repository.delete(sketch);
  }

  Future<Sketch> save(Sketch sketch) async {
    return await _repository.save(sketch);
  }

  Future<Sketch?> getById(String id) async {
    return await _repository.fetchById(id);
  }
}
