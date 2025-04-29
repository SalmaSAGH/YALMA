import 'package:flutter/material.dart';


class TransportStep {
  final String type; // 'walk', 'transport', 'drive', 'train', 'taxi'
  final String instruction;
  final double distance;
  final double duration;
  final IconData icon;
  final Color color;
  final String? lineNumber;
  final String? departureStop;
  final String? arrivalStop;
  final String? departureTime;

  const TransportStep({
    required this.type,
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.icon,
    required this.color,
    this.lineNumber,
    this.departureStop,
    this.arrivalStop,
    this.departureTime,
  });
}