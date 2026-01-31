import 'package:flutter/material.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.order,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final int order;
  final String? imageUrl;
}
