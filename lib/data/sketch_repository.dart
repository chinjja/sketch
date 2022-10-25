import 'package:sketch/model/model.dart';

abstract class SketchRepository {
  Future<void> init();
  Future<List<Sketch>> fetchAll();
  Stream<List<Sketch>> watchAll();
  Future<Sketch?> fetchById(String id);
  Future<Sketch> save(Sketch sketch);
  Future<void> delete(Sketch sketch);
  Future<void> deleteById(String id);
}
