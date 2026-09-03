import 'package:flutter/material.dart';

class DrawingPointModel {
  final Offset point;
  final Color color;
  final double width;

  const DrawingPointModel({
    required this.point,
    required this.color,
    required this.width,
  });

  Map<String, dynamic> toMap() => {
        'x': point.dx,
        'y': point.dy,
        'color': color.value,
        'width': width,
      };

  factory DrawingPointModel.fromMap(Map<String, dynamic> map) {
    return DrawingPointModel(
      point: Offset(
        (map['x'] as num?)?.toDouble() ?? 0,
        (map['y'] as num?)?.toDouble() ?? 0,
      ),
      color: Color((map['color'] as num?)?.toInt() ?? Colors.pink.value),
      width: (map['width'] as num?)?.toDouble() ?? 4,
    );
  }
}

class DrawingStroke {
  final String id;
  final List<DrawingPointModel> points;

  const DrawingStroke({
    required this.id,
    required this.points,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'points': points.map((e) => e.toMap()).toList(),
      };

  factory DrawingStroke.fromMap(Map<String, dynamic> map) {
    return DrawingStroke(
      id: map['id']?.toString() ?? '',
      points: (map['points'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DrawingPointModel.fromMap)
          .toList(),
    );
  }
}
