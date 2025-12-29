import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MeditationType extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final Color color;
  final String subtitle;

  const MeditationType({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.color,
    this.subtitle = '',
  });

  @override
  List<Object?> get props => [id, name, description, imageUrl, color, subtitle];
}
