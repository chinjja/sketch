import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sketch/sketch_repository/sketch_repository.dart';
import 'package:sketch/sketch/cubit/sketch_cubit.dart';

class SketchPage extends StatelessWidget {
  final Sketch sketch;
  const SketchPage({super.key, required this.sketch});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SketchCubit()
        ..started(context.read<SketchRepository>())
        ..sketch(sketch),
      child: BlocListener<SketchCubit, SketchState>(
        listener: (context, state) {
          state.mapOrNull(deleted: (e) {
            Navigator.pop(context);
          });
        },
        child: const SketchView(),
      ),
    );
  }
}

class SketchView extends StatelessWidget {
  const SketchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SketchTitle(),
        actions: [
          const SketchModeButton(
            icon: Icon(Icons.brush),
            mode: SketchMode.pen,
          ),
          const SketchModeButton(
            icon: Icon(Icons.cleaning_services),
            mode: SketchMode.eraser,
          ),
          const UndoButton(),
          const RedoButton(),
          IconButton(
            onPressed: () {
              context.read<SketchCubit>().delete();
            },
            icon: const Icon(Icons.delete),
          ),
          const OpenLayerButton(),
        ],
      ),
      body: Column(
        children: const [
          Expanded(
            child: SketchPaintView(),
          ),
          SketchControlView(),
        ],
      ),
      endDrawer: const Drawer(
        child: SketchLayerDrawer(),
      ),
    );
  }
}

class SketchModeButton extends StatelessWidget {
  final SketchMode mode;
  final Icon icon;
  const SketchModeButton({
    super.key,
    required this.mode,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return IconButton(
          icon: icon,
          isSelected: state.mapOrNull(
            success: (e) => e.mode == mode,
          ),
          onPressed: () => context.read<SketchCubit>().mode(mode),
        );
      },
    );
  }
}

class OpenLayerButton extends StatelessWidget {
  const OpenLayerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return state.maybeMap(
          success: (e) => TextButton.icon(
            onPressed: () {
              final state = Scaffold.of(context);
              if (state.isEndDrawerOpen) {
                state.closeEndDrawer();
              } else {
                state.openEndDrawer();
              }
            },
            icon: const Icon(Icons.list),
            label: Text(e.sketch.activeLayer.title),
          ),
          orElse: () => const CircularProgressIndicator(),
        );
      },
    );
  }
}

class SketchLayerDrawer extends StatelessWidget {
  const SketchLayerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return state.maybeMap(
          success: (e) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Layer'),
                  onPressed: () {
                    context.read<SketchCubit>().addLayer();
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: e.sketch.layers.length,
                  itemBuilder: (context, index) {
                    final layer = e.sketch.layers[index];
                    return SketchLayerItemView(
                      sketch: e.sketch,
                      layer: layer,
                    );
                  },
                ),
              ),
            ],
          ),
          orElse: () => const CircularProgressIndicator(),
        );
      },
    );
  }
}

class SketchLayerItemView extends StatelessWidget {
  final Sketch sketch;
  final SketchLayer layer;
  const SketchLayerItemView({
    super.key,
    required this.sketch,
    required this.layer,
  });

  @override
  Widget build(BuildContext context) {
    final selected = sketch.activeLayerId == layer.id;
    return ListTile(
      visualDensity: const VisualDensity(vertical: 3),
      selectedTileColor: Colors.grey.shade200,
      selected: selected,
      leading: SketchLayerThumbnailView(
        layer: layer,
        sketch: sketch,
        size: 60,
      ),
      title: Row(
        children: [
          layer.visible
              ? const Icon(Icons.visibility)
              : const Icon(Icons.visibility_off),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              initialValue: layer.title,
              decoration: const InputDecoration(
                hintText: '제목 없음',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                context.read<SketchCubit>().updateLayerTitle(layer, value);
              },
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: selected
            ? null
            : () {
                context.read<SketchCubit>().deleteLayer(layer);
              },
      ),
      onTap: () {
        context.read<SketchCubit>().activeLayer(layer);
      },
    );
  }
}

class UndoButton extends StatelessWidget {
  const UndoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return IconButton(
          onPressed: state.mapOrNull(
            success: (e) => e.canUndo
                ? () {
                    context.read<SketchCubit>().undo();
                  }
                : null,
          ),
          icon: const Icon(Icons.undo),
        );
      },
    );
  }
}

class RedoButton extends StatelessWidget {
  const RedoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return IconButton(
          onPressed: state.mapOrNull(
            success: (e) => e.canRedo
                ? () {
                    context.read<SketchCubit>().redo();
                  }
                : null,
          ),
          icon: const Icon(Icons.redo),
        );
      },
    );
  }
}

class SketchTitle extends StatelessWidget {
  const SketchTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return TextFormField(
          initialValue: state.maybeMap(
            success: (e) => e.sketch.title,
            orElse: () => '',
          ),
          decoration: const InputDecoration(
            hintText: '제목 없음',
            border: InputBorder.none,
          ),
          onChanged: (text) => context.read<SketchCubit>().setTitle(text),
        );
      },
    );
  }
}

class SketchPaintView extends StatelessWidget {
  const SketchPaintView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        return state.maybeMap(
          success: (e) => LayoutBuilder(builder: (context, constraints) {
            return GestureDetector(
              onPanStart: (details) {
                context
                    .read<SketchCubit>()
                    .begin(details.localPosition, constraints.biggest);
              },
              onPanUpdate: (details) {
                context.read<SketchCubit>().append(details.localPosition);
              },
              onPanEnd: (details) {
                context.read<SketchCubit>().end();
              },
              child: SketchCanvasView(
                sketch: e.sketch,
                activeLine: e.activeLine,
              ),
            );
          }),
          orElse: () => const CircularProgressIndicator(),
        );
      },
    );
  }
}

class SketchCanvasView extends StatelessWidget {
  final Sketch sketch;
  final SketchLine? activeLine;
  final Rect? clip;
  const SketchCanvasView({
    super.key,
    required this.sketch,
    this.activeLine,
    this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final layer in sketch.layers) ...[
          if (layer.visible) SketchLayerView(layer: layer, clip: clip),
          if (layer.id == sketch.activeLayerId && activeLine != null)
            CustomPaint(
              size: Size.infinite,
              painter: SketchPainter([activeLine!], clip),
            ),
        ]
      ],
    );
  }
}

class SketchLayerView extends StatelessWidget {
  final SketchLayer layer;
  final Rect? clip;
  const SketchLayerView({
    super.key,
    required this.layer,
    this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        size: Size.infinite,
        painter: SketchPainter(layer.lines, clip),
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final Rect? clip;
  final List<SketchLine> sketches;

  const SketchPainter(this.sketches, [this.clip]);

  @override
  void paint(Canvas canvas, Size size) {
    if (clip != null) {
      canvas.clipRect(clip!);
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final paint = Paint();
    for (final sketch in sketches) {
      paint
        ..color = sketch.pen.color
        ..strokeWidth = sketch.pen.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPoints(PointMode.polygon, sketch.points, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return sketches != oldDelegate.sketches;
  }
}

class SketchControlView extends StatelessWidget {
  const SketchControlView({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SketchColorPicker(
          key: Key('SketchView_ColorPicker'),
        ),
        Expanded(
          child: StrokeWidthSlider(
            key: Key('SketchView_StrokeWidthSlider'),
          ),
        ),
        SketchClearButton(
          key: Key('SketchView_ClearButton'),
        ),
      ],
    );
  }
}

class SketchColorPicker extends StatelessWidget {
  const SketchColorPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) => state.maybeMap(
        success: (e) {
          return GestureDetector(
            onTap: () {
              final bloc = context.read<SketchCubit>();
              showDialog<Color>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pick a color!'),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: e.sketch.pen.color,
                      onColorChanged: (color) {
                        bloc.setColor(color);
                        Navigator.of(context).pop(color);
                      },
                    ),
                  ),
                ),
              );
            },
            child: Container(
              width: 60,
              height: 60,
              color: e.sketch.pen.color,
            ),
          );
        },
        orElse: () => const CircularProgressIndicator(),
      ),
    );
  }
}

class StrokeWidthSlider extends StatelessWidget {
  const StrokeWidthSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) => state.maybeMap(
        success: (e) => Slider(
          min: 1,
          max: 100,
          value: e.sketch.pen.strokeWidth,
          onChanged: (value) =>
              context.read<SketchCubit>().setStrokeWidth(value),
        ),
        orElse: () => const CircularProgressIndicator(),
      ),
    );
  }
}

class SketchClearButton extends StatelessWidget {
  const SketchClearButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<SketchCubit>().clear();
      },
      child: const Text('Clear'),
    );
  }
}

class SketchThumbnailView extends StatelessWidget {
  final Sketch sketch;
  final double size;

  const SketchThumbnailView({
    super.key,
    required this.sketch,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final mat = Matrix4.identity()
      ..scale(size / max(sketch.viewport.width, sketch.viewport.height));
    return Container(
      color: Colors.white,
      width: size,
      height: size,
      child: Transform(
        transform: mat,
        child: SketchCanvasView(
          sketch: sketch,
          clip: sketch.viewport.toRect(),
        ),
      ),
    );
  }
}

class SketchLayerThumbnailView extends StatelessWidget {
  final Sketch sketch;
  final SketchLayer layer;
  final double size;
  const SketchLayerThumbnailView({
    super.key,
    required this.sketch,
    required this.layer,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final mat = Matrix4.identity()
      ..scale(size / max(sketch.viewport.width, sketch.viewport.height));
    return Container(
      color: Colors.white,
      width: size,
      height: size,
      child: Transform(
        transform: mat,
        child: SketchLayerView(
          layer: layer,
          clip: sketch.viewport.toRect(),
        ),
      ),
    );
  }
}
