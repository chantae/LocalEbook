import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/color_picker_row.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class AdminBusinessPagesPage extends StatefulWidget {
  const AdminBusinessPagesPage({super.key});

  @override
  State<AdminBusinessPagesPage> createState() => _AdminBusinessPagesPageState();
}

class _AdminBusinessPagesPageState extends State<AdminBusinessPagesPage> {
  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance.collection('business_pages');
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

  Future<void> _showBusinessPageDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final idController = TextEditingController(text: docId ?? '');
    final businessController =
        TextEditingController(text: data?['businessId'] as String? ?? '');
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
                AdminTextField(
                  label: '업체 ID',
                  controller: businessController,
                  helperText: '예: food_1, beauty_2 ...',
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
                      : (value) => _collection()
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
      'businessId': businessController.text.trim(),
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

    await _collection().doc(id).set(payload, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업체 페이지 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBusinessPageDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collection().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '업체 페이지를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 업체 페이지가 없습니다.'));
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
              final labelA = dataA['label'] as String? ?? a.id;
              final labelB = dataB['label'] as String? ?? b.id;
              return labelA.compareTo(labelB);
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
                  title: Text(data['label'] as String? ?? doc.id),
                  subtitle: Text(
                    '업체 ID: ${data['businessId'] ?? ''} / 순서: $orderText',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBusinessPageDialog(
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
