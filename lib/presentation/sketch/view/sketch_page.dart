import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:sketch/presentation/presentation.dart';

class SketchPage extends StatelessWidget {
  final String sketchId;
  const SketchPage({super.key, required this.sketchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SketchCubit()
        ..started(context.read<SketchService>())
        ..sketch(sketchId),
      child: BlocListener<SketchCubit, SketchState>(
        listener: (context, state) {
          state.mapOrNull(deleted: (e) {
            context.pop();
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
        actions: const [
          UndoButton(),
          RedoButton(),
          VerticalDivider(),
          OpenLayerButton(),
          SketchMoreButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: const [
            Expanded(
              child: ClipRect(child: SketchPaintView()),
            ),
            SketchControlView(),
          ],
        ),
      ),
      endDrawer: const Drawer(
        child: SafeArea(
          child: ClipRect(
            child: SketchLayerDrawer(),
          ),
        ),
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
        return IconButton(
          onPressed: () {
            final state = Scaffold.of(context);
            if (state.isEndDrawerOpen) {
              state.closeEndDrawer();
            } else {
              state.openEndDrawer();
            }
          },
          icon: Row(
            children: [
              Text(
                  state.mapOrNull(success: (e) => e.sketch.activeLayer.title) ??
                      ''),
              const SizedBox(width: 4),
              const Icon(Icons.layers),
            ],
          ),
        );
      },
    );
  }
}

enum SketchMenu {
  delete,
}

class SketchMoreButton extends StatelessWidget {
  const SketchMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SketchMenu>(
      onSelected: (SketchMenu item) {
        if (item == SketchMenu.delete) {
          context.read<SketchCubit>().delete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SketchMenu>>[
        const PopupMenuItem<SketchMenu>(
          value: SketchMenu.delete,
          child: Text('Delete'),
        ),
      ],
    );
  }
}

class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<SketchCubit>().delete();
      },
      icon: const Icon(Icons.delete),
    );
  }
}

class SketchLayerDrawer extends StatelessWidget {
  const SketchLayerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchCubit, SketchState>(
      builder: (context, state) {
        final bloc = context.read<SketchCubit>();
        return state.maybeMap(
          success: (e) => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.title),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final layer = e.sketch.activeLayer;
                          return AlertDialog(
                            title: const Text('Layer Title'),
                            content: TextFormField(
                              initialValue: layer.title,
                              autofocus: true,
                              onChanged: (value) =>
                                  bloc.updateLayerTitle(layer, value),
                            ),
                            actions: [
                              TextButton(
                                child: const Text('??????'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                      context.read<SketchCubit>().addLayer();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      context.read<SketchCubit>().addLayer();
                    },
                  ),
                ],
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    context
                        .read<SketchCubit>()
                        .reorderLayer(oldIndex, newIndex);
                  },
                  itemCount: e.sketch.layers.length,
                  itemBuilder: (context, index) {
                    final layer = e.sketch.layers[index];
                    return ReorderableDragStartListener(
                      key: Key(layer.id),
                      index: index,
                      child: SketchLayerItemView(
                        sketch: e.sketch,
                        layer: layer,
                      ),
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
    return Dismissible(
      key: Key(layer.id),
      background: ColoredBox(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Icon(Icons.delete), Icon(Icons.delete)],
          ),
        ),
      ),
      confirmDismiss: (direction) async => !selected,
      onDismissed: (direction) =>
          context.read<SketchCubit>().deleteLayer(layer),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: 3),
        selectedTileColor: Colors.grey.shade300,
        selected: selected,
        leading: FittedBox(
          fit: BoxFit.cover,
          child: SketchThumbnailView(
            layer: layer,
            sketch: sketch,
          ),
        ),
        trailing: IconButton(
          icon: layer.visible
              ? const Icon(Icons.visibility)
              : const Icon(Icons.visibility_off),
          onPressed: () =>
              context.read<SketchCubit>().toggleVisibleLayer(layer),
        ),
        title: Text(layer.title),
        onTap: () {
          context.read<SketchCubit>().activeLayer(layer);
        },
      ),
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
            hintText: '?????? ??????',
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
            return Transform.translate(
              transformHitTests: false,
              offset: e.sketch.viewport.offset,
              child: GestureDetector(
                onScaleStart: (details) {
                  context.read<SketchCubit>().begin(
                        details.pointerCount,
                        details.localFocalPoint,
                        constraints.biggest,
                      );
                },
                onScaleUpdate: (details) {
                  context.read<SketchCubit>().append(details.localFocalPoint);
                },
                onScaleEnd: (details) {
                  context.read<SketchCubit>().end();
                },
                child: SketchCanvasView(
                  sketch: e.sketch,
                  activeLine: e.activeLine,
                ),
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
          if (layer.visible)
            SketchLayerView(
              layer: layer,
            ),
          if (layer.id == sketch.activeLayerId && activeLine != null)
            CustomPaint(
              size: Size.infinite,
              painter: SketchPainter(
                [activeLine!],
              ),
            ),
        ]
      ],
    );
  }
}

class SketchLayerView extends StatelessWidget {
  final SketchLayer layer;
  const SketchLayerView({
    super.key,
    required this.layer,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        size: Size.infinite,
        painter: SketchPainter(
          layer.lines,
        ),
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<SketchLine> sketches;

  const SketchPainter(this.sketches);

  @override
  void paint(Canvas canvas, Size size) {
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
        SketchModeButton(
          icon: Icon(Icons.brush),
          mode: SketchMode.pen,
        ),
        SketchModeButton(
          icon: Icon(Icons.cleaning_services),
          mode: SketchMode.eraser,
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
  final SketchLayer? layer;

  const SketchThumbnailView({
    super.key,
    required this.sketch,
    this.layer,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: Colors.white,
        width: sketch.viewport.width,
        height: sketch.viewport.height,
        child: Transform.translate(
          offset: sketch.viewport.offset,
          child: layer != null
              ? SketchLayerView(
                  layer: layer!,
                )
              : SketchCanvasView(
                  sketch: sketch,
                ),
        ),
      ),
    );
  }
}
