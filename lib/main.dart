import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sketch/app/app.dart';
import 'package:sketch/data/sketch_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();
  final repo = SharedPreferenceSketchRepository(pref);
  await repo.init();
  runApp(App(sketchRepository: repo));
}
