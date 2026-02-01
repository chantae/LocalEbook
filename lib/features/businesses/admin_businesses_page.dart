import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/debug_log.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/features/categories/admin_categories_page.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class AdminBusinessesPage extends StatefulWidget {
  const AdminBusinessesPage({super.key});

  @override
  State<AdminBusinessesPage> createState() => _AdminBusinessesPageState();
}

class _AdminBusinessesPageState extends State<AdminBusinessesPage> {
  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance.collection('businesses');
  }

  Future<void> _persistOrder(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < docs.length; i++) {
      batch.update(docs[i].reference, {'order': i + 1});
    }
    await batch.commit();
  }

  Future<void> _showBusinessDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final idController = TextEditingController(text: docId ?? '');
    final categoryController =
        TextEditingController(text: data?['categoryId'] as String? ?? '');
    final nameController =
        TextEditingController(text: data?['name'] as String? ?? '');
    final summaryController =
        TextEditingController(text: data?['summary'] as String? ?? '');
    final phoneController =
        TextEditingController(text: data?['phone'] as String? ?? '');
    final addressController =
        TextEditingController(text: data?['address'] as String? ?? '');
    final thumbnailController =
        TextEditingController(text: data?['thumbnailUrl'] as String? ?? '');
    final latitudeController = TextEditingController(
      text: data?['latitude']?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: data?['longitude']?.toString() ?? '',
    );
    final openingHoursController =
        TextEditingController(text: data?['openingHours'] as String? ?? '');
    final closedDaysController =
        TextEditingController(text: data?['closedDays'] as String? ?? '');
    final instagramController =
        TextEditingController(text: data?['instagramUrl'] as String? ?? '');
    final blogController =
        TextEditingController(text: data?['blogUrl'] as String? ?? '');
    final kakaoController =
        TextEditingController(text: data?['kakaoChannelUrl'] as String? ?? '');
    final websiteController =
        TextEditingController(text: data?['websiteUrl'] as String? ?? '');
    final couponController =
        TextEditingController(text: data?['couponImageUrl'] as String? ?? '');
    final tagsController = TextEditingController(
      text: (data?['tags'] as List?)
              ?.whereType<String>()
              .join(', ') ??
          (data?['tags'] as String? ?? ''),
    );
    final orderController =
        TextEditingController(text: (data?['order'] ?? '').toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? '업체 추가' : '업체 수정'),
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
                  seedController: nameController,
                  prefix: 'biz',
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminTextField(
                            label: '카테고리 ID',
                            controller: categoryController,
                            helperText: '등록된 카테고리가 없습니다.',
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminCategoriesPage(),
                                ),
                              );
                            },
                            child: const Text('새 카테고리 추가'),
                          ),
                        ],
                      );
                    }
                    final ids = docs.map((doc) => doc.id).toList();
                    final currentValue = ids.contains(categoryController.text)
                        ? categoryController.text
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: currentValue,
                          decoration: const InputDecoration(
                            labelText: '카테고리',
                            border: OutlineInputBorder(),
                          ),
                          items: ids.map((id) {
                            final name = docs
                                .firstWhere((doc) => doc.id == id)
                                .data()['name'] as String?;
                            return DropdownMenuItem(
                              value: id,
                              child: Text('${name ?? id} ($id)'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            categoryController.text = value ?? '';
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminCategoriesPage(),
                              ),
                            );
                          },
                          child: const Text('새 카테고리 추가'),
                        ),
                      ],
                    );
                  },
                ),
                AdminTextField(label: '업체명', controller: nameController),
                AdminTextField(
                  label: '순서',
                  controller: orderController,
                  keyboardType: TextInputType.number,
                ),
                AdminTextField(
                  label: '요약',
                  controller: summaryController,
                  maxLines: 2,
                ),
                ImageUploadField(
                  label: '업체 카드 섬네일',
                  controller: thumbnailController,
                  helperText: '업체 리스트 카드에 표시됩니다.',
                  storagePath: 'business_thumbnails',
                  onSaved: docId == null
                      ? null
                      : (value) => _collection().doc(docId).set(
                            {'thumbnailUrl': value},
                            SetOptions(merge: true),
                          ),
                ),
                ImageUploadField(
                  label: '쿠폰 이미지',
                  controller: couponController,
                  helperText: '업체 상세 페이지에 표시됩니다.',
                  storagePath: 'business_coupons',
                  onSaved: docId == null
                      ? null
                      : (value) => _collection().doc(docId).set(
                            {'couponImageUrl': value},
                            SetOptions(merge: true),
                          ),
                ),
                AdminTextField(
                  label: '태그(쉼표로 구분)',
                  controller: tagsController,
                  helperText: '예: 브런치, 테이크아웃, 24시',
                ),
                AdminTextField(
                  label: '위도',
                  controller: latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                ),
                AdminTextField(
                  label: '경도',
                  controller: longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                ),
                AdminTextField(
                  label: '영업 시간',
                  controller: openingHoursController,
                  helperText: '예: 10:00 - 22:00',
                ),
                AdminTextField(
                  label: '휴무일',
                  controller: closedDaysController,
                  helperText: '예: 매주 월요일',
                ),
                AdminTextField(label: '전화번호', controller: phoneController),
                AdminTextField(label: '주소', controller: addressController),
                AdminTextField(
                  label: '인스타그램 URL',
                  controller: instagramController,
                ),
                AdminTextField(
                  label: '블로그 URL',
                  controller: blogController,
                ),
                AdminTextField(
                  label: '카카오 채널 URL',
                  controller: kakaoController,
                ),
                AdminTextField(
                  label: '웹사이트 URL',
                  controller: websiteController,
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
      'categoryId': categoryController.text.trim(),
      'name': nameController.text.trim(),
      'summary': summaryController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
    };
    final order = parseOrderInput(orderController.text);
    if (order != null) {
      payload['order'] = order;
    } else if (docId != null) {
      payload['order'] = FieldValue.delete();
    }
    final tags = parseTagsInput(tagsController.text);
    if (tags.isNotEmpty) {
      payload['tags'] = tags;
    } else if (docId != null) {
      payload['tags'] = FieldValue.delete();
    }
    final thumbnailUrl = thumbnailController.text.trim();
    if (thumbnailUrl.isNotEmpty) {
      payload['thumbnailUrl'] = thumbnailUrl;
    } else if (docId != null) {
      payload['thumbnailUrl'] = FieldValue.delete();
    }
    final couponUrl = couponController.text.trim();
    if (couponUrl.isNotEmpty) {
      payload['couponImageUrl'] = couponUrl;
    } else if (docId != null) {
      payload['couponImageUrl'] = FieldValue.delete();
    }
    final latitude = double.tryParse(latitudeController.text.trim());
    if (latitude != null) {
      payload['latitude'] = latitude;
    } else if (docId != null) {
      payload['latitude'] = FieldValue.delete();
    }
    final longitude = double.tryParse(longitudeController.text.trim());
    if (longitude != null) {
      payload['longitude'] = longitude;
    } else if (docId != null) {
      payload['longitude'] = FieldValue.delete();
    }
    final openingHours = openingHoursController.text.trim();
    if (openingHours.isNotEmpty) {
      payload['openingHours'] = openingHours;
    } else if (docId != null) {
      payload['openingHours'] = FieldValue.delete();
    }
    final closedDays = closedDaysController.text.trim();
    if (closedDays.isNotEmpty) {
      payload['closedDays'] = closedDays;
    } else if (docId != null) {
      payload['closedDays'] = FieldValue.delete();
    }
    final instagramUrl = instagramController.text.trim();
    if (instagramUrl.isNotEmpty) {
      payload['instagramUrl'] = instagramUrl;
    } else if (docId != null) {
      payload['instagramUrl'] = FieldValue.delete();
    }
    final blogUrl = blogController.text.trim();
    if (blogUrl.isNotEmpty) {
      payload['blogUrl'] = blogUrl;
    } else if (docId != null) {
      payload['blogUrl'] = FieldValue.delete();
    }
    final kakaoUrl = kakaoController.text.trim();
    if (kakaoUrl.isNotEmpty) {
      payload['kakaoChannelUrl'] = kakaoUrl;
    } else if (docId != null) {
      payload['kakaoChannelUrl'] = FieldValue.delete();
    }
    final websiteUrl = websiteController.text.trim();
    if (websiteUrl.isNotEmpty) {
      payload['websiteUrl'] = websiteUrl;
    } else if (docId != null) {
      payload['websiteUrl'] = FieldValue.delete();
    }

    try {
      debugLog(
        location: 'admin_businesses_page.dart:AdminBusinesses.save',
        message: 'save attempt',
        data: {'id': id, 'categoryId': payload['categoryId']},
        hypothesisId: 'H4',
      );
      await _collection().doc(id).set(payload, SetOptions(merge: true));
      debugLog(
        location: 'admin_businesses_page.dart:AdminBusinesses.save',
        message: 'save success',
        data: {'id': id},
        hypothesisId: 'H4',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업체 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusinessDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collection().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '업체를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 업체가 없습니다.'));
          }
          final sortedDocs = [...docs]
            ..sort((a, b) {
              final dataA = a.data();
              final dataB = b.data();
              final orderA = orderValue(dataA['order'], 9999);
              final orderB = orderValue(dataB['order'], 9999);
              final compare = orderA.compareTo(orderB);
              if (compare != 0) {
                return compare;
              }
              final nameA = dataA['name'] as String? ?? a.id;
              final nameB = dataB['name'] as String? ?? b.id;
              return nameA.compareTo(nameB);
            });
          return ReorderableListView.builder(
            itemCount: sortedDocs.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final updated = [...sortedDocs];
              final item = updated.removeAt(oldIndex);
              updated.insert(newIndex, item);
              await _persistOrder(updated);
              if (mounted) {
                setState(() {});
              }
            },
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data();
              final orderText = orderValue(data['order'], 9999) == 9999
                  ? '-'
                  : orderValue(data['order'], 9999).toString();
              final dragColor =
                  Theme.of(context).colorScheme.primary.withOpacity(0.7);
              return Card(
                key: ValueKey(doc.id),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['name'] as String? ?? doc.id),
                  subtitle: Text(
                    'ID: ${doc.id} / 카테고리: ${data['categoryId'] ?? ''}'
                    ' / 순서: $orderText',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBusinessDialog(
                          context,
                          docId: doc.id,
                          data: data,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _collection().doc(doc.id).delete(),
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.unfold_more_rounded,
                            color: dragColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
