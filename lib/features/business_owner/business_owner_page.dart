import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/models/user_role.dart';
import 'package:my_ebook/services/auth_service.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/color_picker_row.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class BusinessOwnerPage extends StatefulWidget {
  const BusinessOwnerPage({super.key});

  @override
  State<BusinessOwnerPage> createState() => _BusinessOwnerPageState();
}

class _BusinessOwnerPageState extends State<BusinessOwnerPage> {
  final _requestIdController = TextEditingController();
  final _requestNameController = TextEditingController();
  final _requestPhoneController = TextEditingController();
  final _requestAddressController = TextEditingController();
  final _requestNoteController = TextEditingController();
  String? _requestCategoryId;

  final _businessNameController = TextEditingController();
  final _businessSummaryController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessTagsController = TextEditingController();
  String? _businessCategoryId;
  bool _loadedBusiness = false;

  @override
  void dispose() {
    _requestIdController.dispose();
    _requestNameController.dispose();
    _requestPhoneController.dispose();
    _requestAddressController.dispose();
    _requestNoteController.dispose();
    _businessNameController.dispose();
    _businessSummaryController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessTagsController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest(String uid) async {
    if (_requestNameController.text.trim().isEmpty ||
        (_requestCategoryId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체명과 카테고리를 입력하세요.')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('business_requests').add({
      'userId': uid,
      'requestedBusinessId': _requestIdController.text.trim(),
      'name': _requestNameController.text.trim(),
      'categoryId': _requestCategoryId ?? '',
      'phone': _requestPhoneController.text.trim(),
      'address': _requestAddressController.text.trim(),
      'note': _requestNoteController.text.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('업체 신청이 접수되었습니다.')),
    );
  }

  Future<void> _saveBusinessInfo(String businessId) async {
    if (_businessNameController.text.trim().isEmpty ||
        (_businessCategoryId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체명과 카테고리를 입력하세요.')),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .set({
      'name': _businessNameController.text.trim(),
      'summary': _businessSummaryController.text.trim(),
      'phone': _businessPhoneController.text.trim(),
      'address': _businessAddressController.text.trim(),
      'categoryId': _businessCategoryId ?? '',
      'tags': parseTagsInput(_businessTagsController.text),
    }, SetOptions(merge: true));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('업체 정보가 저장되었습니다.')),
    );
  }

  Future<void> _showBusinessPageDialog({
    required String businessId,
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final idController = TextEditingController(text: docId ?? '');
    final labelController =
        TextEditingController(text: data?['label'] as String? ?? '');
    final colorController =
        TextEditingController(text: data?['colorHex'] as String? ?? '#90CAF9');
    final imageController =
        TextEditingController(text: data?['imageUrl'] as String? ?? '');
    final orderController =
        TextEditingController(text: (data?['order'] ?? '').toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? '업체 페이지 추가' : '업체 페이지 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminTextField(
                  label: 'ID',
                  controller: idController,
                  enabled: docId == null,
                ),
                IdActionRow(
                  idController: idController,
                  seedController: labelController,
                  prefix: 'page',
                ),
                AdminTextField(label: '라벨', controller: labelController),
                AdminTextField(
                  label: '순서',
                  controller: orderController,
                  keyboardType: TextInputType.number,
                ),
                AdminTextField(label: '색상(HEX)', controller: colorController),
                ImageUploadField(
                  label: '이미지 URL',
                  controller: imageController,
                  helperText: '업체 페이지 배경 이미지',
                  storagePath: 'business_pages',
                  onSaved: docId == null
                      ? null
                      : (value) => FirebaseFirestore.instance
                          .collection('business_pages')
                          .doc(docId)
                          .set({'imageUrl': value}, SetOptions(merge: true)),
                ),
                ColorPickerRow(
                  controller: colorController,
                  colors: const [
                    Color(0xFF90CAF9),
                    Color(0xFFB39DDB),
                    Color(0xFFFFCC80),
                    Color(0xFFA5D6A7),
                    Color(0xFFFFAB91),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final id = idController.text.trim();
    if (id.isEmpty) {
      return;
    }

    final payload = <String, Object?>{
      'businessId': businessId,
      'label': labelController.text.trim(),
      'colorHex': colorController.text.trim(),
      'imageUrl': imageController.text.trim(),
    };
    final order = parseOrderInput(orderController.text);
    if (order != null) {
      payload['order'] = order;
    } else if (docId != null) {
      payload['order'] = FieldValue.delete();
    }

    await FirebaseFirestore.instance
        .collection('business_pages')
        .doc(id)
        .set(payload, SetOptions(merge: true));
  }

  Widget _buildCategoryDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('등록된 카테고리가 없습니다.');
        }
        final currentValue = docs.any((doc) => doc.id == value) ? value : null;
        return DropdownButtonFormField<String>(
          value: currentValue,
          decoration: const InputDecoration(
            labelText: '카테고리',
            border: OutlineInputBorder(),
          ),
          items: docs.map((doc) {
            final name = doc.data()['name'] as String? ?? doc.id;
            return DropdownMenuItem(
              value: doc.id,
              child: Text('$name (${doc.id})'),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('업체 페이지 관리')),
        body: const Center(
          child: Text('로그인 후 이용할 수 있습니다.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('업체 페이지 관리')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.userDocStream(user.uid),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final role = userRoleFromString(data?['role'] as String?);
          if (role != UserRole.business) {
            return const Center(
              child: Text('업체 회원만 이용할 수 있습니다.'),
            );
          }
          final businessId = data?['businessId'] as String? ?? '';
          if (businessId.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '업체 페이지 신청',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildCategoryDropdown(
                  value: _requestCategoryId,
                  onChanged: (value) =>
                      setState(() => _requestCategoryId = value),
                ),
                const SizedBox(height: 12),
                AdminTextField(label: '업체명', controller: _requestNameController),
                AdminTextField(
                  label: '희망 업체 ID (선택)',
                  controller: _requestIdController,
                  helperText: '예: food_1',
                ),
                AdminTextField(label: '전화번호', controller: _requestPhoneController),
                AdminTextField(label: '주소', controller: _requestAddressController),
                AdminTextField(
                  label: '요청사항',
                  controller: _requestNoteController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _submitRequest(user.uid),
                  child: const Text('신청하기'),
                ),
                const SizedBox(height: 12),
                const Text(
                  '승인 후 관리자가 업체 ID를 지정합니다.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .snapshots(),
            builder: (context, bizSnapshot) {
              final bizData = bizSnapshot.data?.data();
              if (!_loadedBusiness && bizData != null) {
                _loadedBusiness = true;
                _businessNameController.text = bizData['name'] as String? ?? '';
                _businessSummaryController.text =
                    bizData['summary'] as String? ?? '';
                _businessPhoneController.text =
                    bizData['phone'] as String? ?? '';
                _businessAddressController.text =
                    bizData['address'] as String? ?? '';
                _businessCategoryId = bizData['categoryId'] as String?;
                _businessTagsController.text =
                    (bizData['tags'] as List?)?.whereType<String>().join(', ') ??
                        (bizData['tags'] as String? ?? '');
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '내 업체 정보 ($businessId)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(
                    value: _businessCategoryId,
                    onChanged: (value) =>
                        setState(() => _businessCategoryId = value),
                  ),
                  const SizedBox(height: 12),
                  AdminTextField(
                    label: '업체명',
                    controller: _businessNameController,
                  ),
                  AdminTextField(
                    label: '요약',
                    controller: _businessSummaryController,
                    maxLines: 2,
                  ),
                  AdminTextField(
                    label: '전화번호',
                    controller: _businessPhoneController,
                  ),
                  AdminTextField(
                    label: '주소',
                    controller: _businessAddressController,
                  ),
                  AdminTextField(
                    label: '태그(쉼표로 구분)',
                    controller: _businessTagsController,
                    helperText: '예: 예약, 주차, 포장',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _saveBusinessInfo(businessId),
                    child: const Text('업체 정보 저장'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '업체 페이지',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('business_pages')
                        .where('businessId', isEqualTo: businessId)
                        .snapshots(),
                    builder: (context, pageSnapshot) {
                      if (pageSnapshot.hasError) {
                        return Text(
                          '업체 페이지를 불러오지 못했습니다.\n${pageSnapshot.error}',
                        );
                      }
                      final docs = pageSnapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('등록된 업체 페이지가 없습니다.');
                      }
                      final sorted = [...docs]
                        ..sort((a, b) {
                          final dataA = a.data();
                          final dataB = b.data();
                          final orderA = orderValue(dataA['order'], 9999);
                          final orderB = orderValue(dataB['order'], 9999);
                          final compare = orderA.compareTo(orderB);
                          if (compare != 0) {
                            return compare;
                          }
                          final labelA = dataA['label'] as String? ?? a.id;
                          final labelB = dataB['label'] as String? ?? b.id;
                          return labelA.compareTo(labelB);
                        });
                      return Column(
                        children: [
                          for (final doc in sorted)
                            ListTile(
                              title: Text(
                                  doc.data()['label'] as String? ?? doc.id),
                              subtitle: Text(
                                '순서: ${orderValue(doc.data()['order'], 9999)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showBusinessPageDialog(
                                  businessId: businessId,
                                  docId: doc.id,
                                  data: doc.data(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _showBusinessPageDialog(
                                businessId: businessId,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('업체 페이지 추가'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
