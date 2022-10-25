import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/data/sketch_repository_impl.dart';
import 'package:sketch/presentation/presentation.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _MockBehaviorSubject extends Mock
    implements BehaviorSubject<List<Sketch>> {}

void main() {
  late BehaviorSubject<List<Sketch>> subject;
  late SharedPreferences pref;
  late SketchRepository repository;

  setUp(() {
    pref = _MockSharedPreferences();
    subject = _MockBehaviorSubject();
    repository = SharedPreferenceSketchRepository(pref, subject);
  });
  test('fetchAll()', () async {
    final sketch = Sketch.create('1');
    when(() => pref.getStringList('sketch_ids')).thenReturn(['1']);
    when(() => pref.getString('1')).thenReturn(jsonEncode(sketch));
    final res = await repository.fetchAll();
    expect(res, [sketch]);
  });

  test('fetchAll() empty', () async {
    when(() => pref.getStringList('sketch_ids')).thenReturn(null);
    final res = await repository.fetchAll();
    expect(res, []);
  });

  test('findById()', () async {
    final sketch = Sketch.create('1');
    when(() => pref.getString('1')).thenReturn(jsonEncode(sketch));
    final res = await repository.fetchById('1');
    expect(res, sketch);
  });

  test('save() by new object', () async {
    final sketch = Sketch.create('1');
    when(() => pref.getStringList('sketch_ids')).thenReturn([]);
    when(() => pref.setStringList('sketch_ids', [sketch.id]))
        .thenAnswer((_) async => true);
    when(() => pref.getString(sketch.id)).thenReturn(null);
    when(() => pref.setString(sketch.id, jsonEncode(sketch)))
        .thenAnswer((_) async => true);
    when(() => subject.value).thenReturn([]);

    final res = await repository.save(sketch);
    expect(res, sketch);

    verify(() => pref.getStringList('sketch_ids')).called(1);
    verify(() => pref.setStringList('sketch_ids', ['1'])).called(1);
    verify(() => pref.getString('1')).called(1);
    verify(() => pref.setString('1', jsonEncode(sketch))).called(1);
    verifyNoMoreInteractions(pref);

    verify(() => subject.value).called(1);
    verify(() => subject.add([sketch])).called(1);
    verifyNoMoreInteractions(subject);
  });

  test('save() by exists object', () async {
    final sketch = Sketch.create('1');
    when(() => pref.getString(sketch.id)).thenReturn(jsonEncode(sketch));
    when(() => pref.setString(sketch.id, jsonEncode(sketch)))
        .thenAnswer((_) async => true);
    when(() => subject.value).thenReturn([sketch]);

    final res = await repository.save(sketch);
    expect(res, sketch);

    verify(() => pref.getString('1')).called(1);
    verify(() => pref.setString('1', jsonEncode(sketch))).called(1);
    verifyNoMoreInteractions(pref);

    verify(() => subject.value).called(1);
    verify(() => subject.add([sketch])).called(1);
    verifyNoMoreInteractions(subject);
  });

  group('delete()', () {
    late Sketch sketch;
    setUp(() {
      sketch = Sketch.create('1');

      when(() => pref.remove(sketch.id)).thenAnswer((_) async => true);
      when(() => pref.getStringList('sketch_ids')).thenReturn(['1']);
      when(() => pref.setStringList('sketch_ids', []))
          .thenAnswer((_) async => true);
      when(() => subject.value).thenReturn([sketch]);
    });
    tearDown(() {
      verify(() => pref.getStringList('sketch_ids')).called(1);
      verify(() => pref.setStringList('sketch_ids', [])).called(1);
      verify(() => pref.remove('1')).called(1);
      verifyNoMoreInteractions(pref);

      verify(() => subject.value).called(1);
      verify(() => subject.add([])).called(1);
      verifyNoMoreInteractions(subject);
    });
    test('by object', () async {
      await repository.delete(sketch);
    });
    test('by id', () async {
      await repository.deleteById(sketch.id);
    });
  });
}
