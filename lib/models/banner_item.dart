import 'package:flutter/material.dart';

class BannerItem {
  const BannerItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.order,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final Color? color;
  final int order;
  final String? imageUrl;
}
