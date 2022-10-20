import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sketch/sketch/view/view.dart';
import 'package:sketch/sketch_list/cubit/sketch_list_cubit.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';

class SketchListPage extends StatelessWidget {
  const SketchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SketchListCubit()..started(context.read<SketchRepository>()),
      child: BlocListener<SketchListCubit, SketchListState>(
        listener: (context, state) {
          state.mapOrNull(created: (e) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SketchPage(sketch: e.sketch),
              ),
            );
          });
        },
        child: const SketchListView(),
      ),
    );
  }
}

class SketchListView extends StatelessWidget {
  const SketchListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sketch Book'),
      ),
      body: const Center(child: SketchItemListView()),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.read<SketchListCubit>().create(),
      ),
    );
  }
}

class SketchItemListView extends StatelessWidget {
  const SketchItemListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchListCubit, SketchListState>(
      builder: (context, state) {
        return state.maybeMap(
          success: (e) => e.sketches.isEmpty
              ? const Text('Empty')
              : ListView.builder(
                  itemCount: e.sketches.length,
                  itemBuilder: (context, index) {
                    final sketch = e.sketches[index];
                    return SketchItemView(
                      key: Key(sketch.id),
                      sketch: sketch,
                    );
                  },
                ),
          orElse: () => const CircularProgressIndicator(),
        );
      },
    );
  }
}

class SketchItemView extends StatelessWidget {
  final Sketch sketch;
  const SketchItemView({super.key, required this.sketch});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: 3),
      leading: SketchThumbnailView(
        sketch: sketch,
        size: 60,
      ),
      title: sketch.title.isEmpty
          ? Text(
              '제목 없음',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Text(sketch.title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SketchPage(sketch: sketch),
          ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          context.read<SketchListCubit>().delete(sketch);
        },
      ),
    );
  }
}
