import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/app/app.dart';
import 'package:sketch/data/sketch_repository_impl.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final pref = _MockSharedPreferences();
    when(() => pref.getStringList(any())).thenReturn([]);
    final repository = SharedPreferenceSketchRepository(pref);

    // Build our app and trigger a frame.
    await tester.pumpWidget(App(sketchRepository: repository));
    expect(find.byType(App), findsOneWidget);
  });
}
