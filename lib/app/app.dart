import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sketch/data/sketch_repository.dart';
import 'package:sketch/presentation/presentation.dart';

class App extends StatelessWidget {
  final SketchRepository sketchRepository;
  App({super.key, required this.sketchRepository});

  late final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/sketches',
      ),
      GoRoute(
        path: '/sketches',
        builder: (context, state) {
          return const SketchListPage();
        },
        routes: [
          GoRoute(
            path: ':sketchId',
            builder: (context, state) {
              return SketchPage(sketchId: state.params['sketchId']!);
            },
          ),
        ],
      ),
    ],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SketchService(sketchRepository),
      child: MaterialApp.router(
        title: 'Sketch Book',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        routerConfig: _router,
      ),
    );
  }
}
