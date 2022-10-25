import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/data/sketch_repository_impl.dart';
import 'package:sketch/presentation/presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();
  final repo = SharedPreferenceSketchRepository(pref);
  await repo.init();
  runApp(SketchApp(sketchRepository: repo));
}

class SketchApp extends StatelessWidget {
  final SketchRepository sketchRepository;
  const SketchApp({super.key, required this.sketchRepository});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SketchService(sketchRepository),
      child: MaterialApp(
        title: 'Sketch Book',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const SketchListPage(),
      ),
    );
  }
}
