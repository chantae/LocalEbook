import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/features/admin/admin_home_page.dart';

class AdminGatePage extends StatefulWidget {
  const AdminGatePage({super.key});

  @override
  State<AdminGatePage> createState() => _AdminGatePageState();
}

class _AdminGatePageState extends State<AdminGatePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  Future<String> _fetchAccessCode() async {
    if (Firebase.apps.isEmpty) {
      return '0000';
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('config')
          .get();
      return doc.data()?['accessCode'] as String? ?? '0000';
    } catch (_) {
      return '0000';
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    try {
      final expected = await _fetchAccessCode();
      if (_codeController.text.trim() == expected) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomePage()),
        );
      } else {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('접근 코드가 올바르지 않습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              obscureText: true,
              onSubmitted: (_) => _loading ? null : _handleLogin(),
              decoration: const InputDecoration(
                labelText: '접근 코드',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
