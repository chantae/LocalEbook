import 'package:flutter/material.dart';

class BusinessPage {
  const BusinessPage({
    required this.id,
    required this.businessId,
    required this.label,
    required this.color,
    required this.order,
    this.imageUrl,
  });

  final String id;
  final String businessId;
  final String label;
  final Color color;
  final int order;
  final String? imageUrl;
}
