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
          const UndoButton(),
          const RedoButton(),
          IconButton(
            onPressed: () {
              context.read<SketchCubit>().delete();
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: const [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: SketchPaintView(),
              ),
            ),
          ),
          SketchControlView(),
        ],
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
            return Transform(
              transform: Matrix4.diagonal3Values(1, 1, 1),
              child: GestureDetector(
                onPanStart: (details) {
                  context
                      .read<SketchCubit>()
                      .begin(details.localPosition, constraints.biggest);
                },
                onPanUpdate: (details) {
                  context
                      .read<SketchCubit>()
                      .append(details.localPosition, constraints.biggest);
                },
                onPanEnd: (details) {
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
  const SketchCanvasView({
    super.key,
    required this.sketch,
    this.activeLine,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
        ),
        ...sketch.lines.map(
          (line) => Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: SketchPainter(line),
              ),
            ),
          ),
        ),
        if (activeLine != null)
          CustomPaint(
            size: Size.infinite,
            painter: SketchPainter(activeLine!),
          ),
      ],
    );
  }
}

class SketchPainter extends CustomPainter {
  final SketchLine sketch;

  const SketchPainter(this.sketch);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.scale(size.width, size.height);
    final paint = Paint()
      ..color = sketch.color
      ..strokeWidth = sketch.strokeWidth / 100
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPoints(PointMode.polygon, sketch.points, paint);
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return sketch != oldDelegate.sketch;
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
                      pickerColor: e.sketch.color,
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
              color: e.sketch.color,
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
          max: 20,
          value: e.sketch.strokeWidth,
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
