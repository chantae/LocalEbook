import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _accessCodeController = TextEditingController();
  final _mainIconController = TextEditingController();
  final _mainIconImageController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _mainIconController.dispose();
    _mainIconImageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('admin_settings')
        .doc('config')
        .get();
    final data = doc.data() ?? {};
    _accessCodeController.text = data['accessCode'] as String? ?? '0000';
    _mainIconController.text = data['mainIcon'] as String? ?? 'tag';
    _mainIconImageController.text = data['mainIconImageUrl'] as String? ?? '';
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('config')
          .set(
        {
          'accessCode': _accessCodeController.text.trim(),
          'mainIcon': _mainIconController.text.trim().isEmpty
              ? 'tag'
              : _mainIconController.text.trim(),
          'mainIconImageUrl': _mainIconImageController.text.trim(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 완료')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminTextField(
            label: '접근 코드',
            controller: _accessCodeController,
          ),
          DropdownButtonFormField<String>(
            value: _mainIconController.text.isEmpty
                ? null
                : _mainIconController.text,
            decoration: const InputDecoration(
              labelText: '메인 아이콘',
              border: OutlineInputBorder(),
            ),
            items: iconOptions.map((option) {
              return DropdownMenuItem(
                value: option.name,
                child: Row(
                  children: [
                    Icon(option.icon),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              _mainIconController.text = value ?? 'tag';
            },
          ),
          const SizedBox(height: 12),
          ImageUploadField(
            label: '메인 아이콘 이미지 URL',
            controller: _mainIconImageController,
            helperText: '업로드 시 자동으로 저장됩니다.',
            storagePath: 'main_icons',
            onSaved: (value) {
              FirebaseFirestore.instance
                  .collection('admin_settings')
                  .doc('config')
                  .set({'mainIconImageUrl': value}, SetOptions(merge: true));
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
