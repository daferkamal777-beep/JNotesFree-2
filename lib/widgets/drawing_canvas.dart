import 'package:flutter/material.dart';
import '../models/stroke.dart';

enum DrawingTool { pen, highlighter, eraser }

class DrawingCanvas extends StatefulWidget {
  final List<InkStroke> strokes;
  final ValueChanged<List<InkStroke>> onChanged;
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.onChanged,
    required this.tool,
    required this.color,
    required this.strokeWidth,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  InkStroke? _current;

  void _start(Offset p) {
    if (widget.tool == DrawingTool.eraser) {
      _eraseAt(p);
      return;
    }
    _current = InkStroke(
      points: [StrokePoint(x: p.dx, y: p.dy)],
      colorValue: widget.color.value,
      width: widget.strokeWidth,
      highlighter: widget.tool == DrawingTool.highlighter,
    );
    setState(() {});
  }

  void _move(Offset p) {
    if (widget.tool == DrawingTool.eraser) {
      _eraseAt(p);
      return;
    }
    if (_current == null) return;
    _current!.points.add(StrokePoint(x: p.dx, y: p.dy));
    setState(() {});
  }

  void _end() {
    if (_current == null) return;
    final updated = [...widget.strokes, _current!];
    _current = null;
    widget.onChanged(updated);
    setState(() {});
  }

  void _eraseAt(Offset p) {
    const radius = 22.0;
    final kept = widget.strokes.where((s) {
      return !s.points.any((sp) => (sp.offset - p).distance <= radius);
    }).toList();
    if (kept.length != widget.strokes.length) {
      widget.onChanged(kept);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _start(d.localPosition),
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _end(),
      child: CustomPaint(
        painter: _InkPainter(
          strokes: widget.strokes,
          current: _current,
          background: Theme.of(context).colorScheme.surface,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  final List<InkStroke> strokes;
  final InkStroke? current;
  final Color background;

  _InkPainter({
    required this.strokes,
    required this.current,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);
    for (final stroke in [...strokes, if (current != null) current!]) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.colorValue).withOpacity(
          stroke.highlighter ? 0.28 : 1.0,
        )
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first.offset,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()..moveTo(
          stroke.points.first.x,
          stroke.points.first.y,
        );
      for (var i = 1; i < stroke.points.length; i++) {
        final a = stroke.points[i - 1].offset;
        final b = stroke.points[i].offset;
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        path.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}
