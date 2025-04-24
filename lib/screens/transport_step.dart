import 'package:flutter/material.dart';


class TransportStep {
  final String type; // 'walk', 'transport', 'drive'
  final String instruction;
  final double distance; // en mètres
  final double duration; // en secondes
  final IconData icon;
  final Color color;

  // Pour les transports en commun
  final String? lineNumber;
  final String? departureStop;
  final String? arrivalStop;
  final String? departureTime;

  TransportStep({
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