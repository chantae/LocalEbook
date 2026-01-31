import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';

class AdminTextField extends StatelessWidget {
  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          helperText: helperText,
        ),
      ),
    );
  }
}

class IdActionRow extends StatelessWidget {
  const IdActionRow({
    super.key,
    required this.idController,
    required this.seedController,
    required this.prefix,
  });

  final TextEditingController idController;
  final TextEditingController seedController;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                final id = generateId(seedController.text, prefix: prefix);
                idController.text = id;
              },
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('ID 자동 생성'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => copyToClipboard(context, idController.text),
              icon: const Icon(Icons.copy),
              label: const Text('복사'),
            ),
          ),
        ],
      ),
    );
  }
}
