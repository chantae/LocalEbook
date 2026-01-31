import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.controller,
    required this.colors,
  });

  final TextEditingController controller;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        return InkWell(
          onTap: () => controller.text = hexFromColor(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
