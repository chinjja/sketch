import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/model/model.dart';
import 'package:sketch/service/sketch_service.dart';

class _MockSketchRepository extends Mock implements SketchRepository {}

void main() {
  late SketchRepository repository;
  late SketchService service;
  late Sketch sketch;

  setUp(() {
    repository = _MockSketchRepository();
    service = SketchService(repository);
    sketch = Sketch.create('1');
  });
  test('delete()', () async {
    when(() => repository.delete(sketch)).thenAnswer((_) async => {});
    await service.delete(sketch);

    verify(() => repository.delete(sketch)).called(1);
  });

  test('save()', () async {
    when(() => repository.save(sketch)).thenAnswer((_) async => sketch);
    final res = await service.save(sketch);
    expect(res, sketch);

    verify(() => repository.save(sketch)).called(1);
  });

  test('getById()', () async {
    when(() => repository.fetchById('1')).thenAnswer((_) async => sketch);
    final res = await service.getById('1');
    expect(res, sketch);

    verify(() => repository.fetchById('1')).called(1);
  });

  test('watch', () {
    when(() => repository.watchAll()).thenAnswer((_) => Stream.fromIterable([
          [sketch],
          [sketch, sketch],
        ]));

    expect(
        service.onSketches,
        emitsInOrder([
          [sketch],
          [sketch, sketch],
        ]));
  });
}
