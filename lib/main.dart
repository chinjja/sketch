import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/sketch_list/view/view.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();
  runApp(SketchApp(preferences: pref));
}

class SketchApp extends StatelessWidget {
  final SharedPreferences preferences;
  const SketchApp({super.key, required this.preferences});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SketchRepository(preferences),
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
