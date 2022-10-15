import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sketch/sketch_list/view/view.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

void main() {
  runApp(const SketchApp());
}

class SketchApp extends StatelessWidget {
  const SketchApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SketchRepository(),
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
