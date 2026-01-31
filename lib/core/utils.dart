import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) {
    return fallback;
  }
  final normalized = hex.replaceAll('#', '');
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }
  if (normalized.length == 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value);
}

String hexFromColor(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0');
  return '#${value.substring(2)}';
}

IconData iconFromName(String? name, IconData fallback) {
  switch (name) {
    case 'restaurant':
      return Icons.restaurant;
    case 'spa':
      return Icons.spa;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'school':
      return Icons.school;
    case 'palette':
      return Icons.palette;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'support_agent':
      return Icons.support_agent;
    default:
      return fallback;
  }
}

String iconNameFromIcon(IconData icon) {
  if (icon == Icons.restaurant) {
    return 'restaurant';
  }
  if (icon == Icons.spa) {
    return 'spa';
  }
  if (icon == Icons.fitness_center) {
    return 'fitness_center';
  }
  if (icon == Icons.school) {
    return 'school';
  }
  if (icon == Icons.palette) {
    return 'palette';
  }
  if (icon == Icons.local_cafe) {
    return 'local_cafe';
  }
  if (icon == Icons.local_hospital) {
    return 'local_hospital';
  }
  if (icon == Icons.support_agent) {
    return 'support_agent';
  }
  return 'tag';
}

String slugify(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.toLowerCase().codeUnits) {
    final isLetter = codeUnit >= 97 && codeUnit <= 122;
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    if (isLetter || isDigit) {
      buffer.writeCharCode(codeUnit);
    } else if (buffer.isNotEmpty && !buffer.toString().endsWith('_')) {
      buffer.write('_');
    }
  }
  final slug = buffer.toString().replaceAll(RegExp(r'_+$'), '');
  return slug;
}

String generateId(String seed, {String prefix = 'item'}) {
  final slug = slugify(seed);
  final base = slug.isEmpty ? prefix : '${prefix}_$slug';
  final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
  return '${base}_$suffix';
}

Future<void> copyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('복사됨: $value')),
    );
  }
}

Future<String?> uploadImageToStorage(
  BuildContext context, {
  required String pathPrefix,
  ValueChanged<double>? onProgress,
  bool allowMultiple = false,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: allowMultiple,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  final urls = <String>[];
  for (var i = 0; i < result.files.length; i++) {
    final file = result.files[i];
    final bytes = file.bytes;
    if (bytes == null) {
      continue;
    }
    final filename = file.name.isEmpty ? 'upload' : file.name;
    final ref = FirebaseStorage.instance.ref().child(
          '$pathPrefix/${DateTime.now().millisecondsSinceEpoch}_${i}_$filename',
        );
    final metadata = SettableMetadata(
      contentType: guessContentType(filename, file.extension),
    );
    final task = ref.putData(bytes, metadata);
    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0 && onProgress != null) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });
    await task;
    urls.add(await ref.getDownloadURL());
  }
  if (urls.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
    );
    return null;
  }
  return urls.join('\n');
}

Future<void> deleteStorageUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return;
  }
  final urls = trimmed.split('\n').map((value) => value.trim()).toList();
  for (final item in urls) {
    if (item.isEmpty) {
      continue;
    }
    final ref = FirebaseStorage.instance.refFromURL(item);
    await ref.delete();
  }
}

String guessContentType(String filename, String? extension) {
  final ext = (extension ?? filename.split('.').last).toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'svg':
      return 'image/svg+xml';
    default:
      return 'image/*';
  }
}

int orderValue(Object? value, int fallback) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

int? parseOrderInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return int.tryParse(trimmed);
}

List<String> parseTagsInput(String value) {
  if (value.trim().isEmpty) {
    return [];
  }
  final parts = value
      .split(RegExp(r'[,\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final seen = <String>{};
  final unique = <String>[];
  for (final part in parts) {
    if (seen.add(part)) {
      unique.add(part);
    }
  }
  return unique;
}

const iconOptions = [
  IconOption(name: 'restaurant', icon: Icons.restaurant, label: '음식점'),
  IconOption(name: 'spa', icon: Icons.spa, label: '뷰티'),
  IconOption(name: 'fitness_center', icon: Icons.fitness_center, label: '운동'),
  IconOption(name: 'school', icon: Icons.school, label: '학원'),
  IconOption(name: 'palette', icon: Icons.palette, label: '취미'),
  IconOption(name: 'local_cafe', icon: Icons.local_cafe, label: '카페'),
  IconOption(name: 'local_hospital', icon: Icons.local_hospital, label: '병원'),
  IconOption(
    name: 'support_agent',
    icon: Icons.support_agent,
    label: '전문가 서비스',
  ),
];

class IconOption {
  const IconOption({
    required this.name,
    required this.icon,
    required this.label,
  });

  final String name;
  final IconData icon;
  final String label;
}
