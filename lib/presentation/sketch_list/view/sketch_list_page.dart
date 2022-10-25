import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sketch/presentation/presentation.dart';

class SketchListPage extends StatelessWidget {
  const SketchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SketchListCubit()..started(context.read<SketchService>()),
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
                    return Dismissible(
                      key: Key(sketch.id),
                      background: ColoredBox(
                        color: Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(Icons.delete),
                              Icon(Icons.delete),
                            ],
                          ),
                        ),
                      ),
                      onDismissed: (direction) =>
                          context.read<SketchListCubit>().delete(sketch),
                      child: SketchItemView(
                        sketch: sketch,
                      ),
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
    );
  }
}
