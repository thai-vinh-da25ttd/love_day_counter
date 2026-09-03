import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/drawing_model.dart';
import '../../repositories/canvas_repository.dart';

class CanvasScreen extends StatefulWidget {
  final String coupleId;

  const CanvasScreen({
    super.key,
    required this.coupleId,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final _uuid = const Uuid();
  final List<DrawingStroke> _strokes = [];
  DrawingStroke? _activeStroke;
  Timer? _saveTimer;
  bool _loading = true;
  Color _color = Colors.white;
  double _width = 5;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _save);
  }

  Future<void> _save() async {
    await CanvasRepository.instance.save(
      coupleId: widget.coupleId,
      strokes: _strokes.map((s) => s.toMap()).toList(),
    );
  }

  void _startStroke(Offset position) {
    setState(() {
      _activeStroke = DrawingStroke(
        id: _uuid.v4(),
        points: [
          DrawingPointModel(
            point: position,
            color: _color,
            width: _width,
          ),
        ],
      );
    });
  }

  void _moveStroke(Offset position) {
    if (_activeStroke == null) return;

    setState(() {
      _activeStroke = DrawingStroke(
        id: _activeStroke!.id,
        points: [
          ..._activeStroke!.points,
          DrawingPointModel(
            point: position,
            color: _color,
            width: _width,
          ),
        ],
      );
    });
  }

  void _endStroke() {
    if (_activeStroke == null) return;

    setState(() {
      _strokes.add(_activeStroke!);
      _activeStroke = null;
    });

    _scheduleSave();
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
    _scheduleSave();
  }

  List<DrawingStroke> _readRemote(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return [];

    return (data['strokes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DrawingStroke.fromMap)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vẽ cùng nhau'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: CanvasRepository.instance.stream(widget.coupleId),
        builder: (context, snapshot) {
          if (!_loading && !snapshot.hasData) {
            return const Center(child: Text('Không thể tải canvas.'));
          }

          if (snapshot.hasData && _loading) {
            final remote = _readRemote(snapshot.data!);
            _strokes
              ..clear()
              ..addAll(remote);
            _loading = false;
          }

          final allStrokes = [
            ..._strokes,
            if (_activeStroke != null) _activeStroke!,
          ];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _color = Colors.white),
                      icon: const Icon(Icons.circle),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _color = Colors.black),
                      icon: const Icon(Icons.circle, color: Colors.black),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _color = Colors.red),
                      icon: const Icon(Icons.circle, color: Colors.red),
                    ),
                    Expanded(
                      child: Slider(
                        value: _width,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _width = v),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF2F2F2),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => _startStroke(d.localPosition),
                    onPanUpdate: (d) => _moveStroke(d.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    child: CustomPaint(
                      painter: _CanvasPainter(allStrokes),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  _CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.points.first.color
        ..strokeWidth = stroke.points.first.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          stroke.points[i].point,
          stroke.points[i + 1].point,
          paint,
        );
      }

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first.point,
          stroke.points.first.width / 2,
          paint..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
