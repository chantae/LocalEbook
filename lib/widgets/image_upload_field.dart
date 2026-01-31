import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';

class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.controller,
    this.helperText,
    required this.storagePath,
    this.onSaved,
    this.allowMultiple = false,
  });

  final String label;
  final TextEditingController controller;
  final String? helperText;
  final String storagePath;
  final ValueChanged<String>? onSaved;
  final bool allowMultiple;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  double _progress = 0;
  bool _uploading = false;

  Future<void> _handleUpload() async {
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    final url = await uploadImageToStorage(
      context,
      pathPrefix: widget.storagePath,
      allowMultiple: widget.allowMultiple,
      onProgress: (value) => setState(() => _progress = value),
    );
    if (url != null) {
      widget.controller.text = url;
      widget.onSaved?.call(url);
    }
    if (mounted) {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          maxLines: widget.allowMultiple ? 3 : 1,
          decoration: InputDecoration(
            hintText: '이미지 URL',
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _uploading ? null : _handleUpload,
              icon: const Icon(Icons.upload),
              label: Text(_uploading ? '업로드 중' : '이미지 업로드'),
            ),
            const SizedBox(width: 12),
            if (_uploading)
              Expanded(
                child: LinearProgressIndicator(value: _progress),
              ),
          ],
        ),
      ],
    );
  }
}
