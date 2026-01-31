import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/color_picker_row.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class AdminBannersPage extends StatefulWidget {
  const AdminBannersPage({super.key});

  @override
  State<AdminBannersPage> createState() => _AdminBannersPageState();
}

class _AdminBannersPageState extends State<AdminBannersPage> {
  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance.collection('banners');
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

  Future<void> _showBannerDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final idController = TextEditingController(text: docId ?? '');
    final titleController =
        TextEditingController(text: data?['title'] as String? ?? '');
    final subtitleController =
        TextEditingController(text: data?['subtitle'] as String? ?? '');
    final colorController =
        TextEditingController(text: data?['colorHex'] as String? ?? '#8E99F3');
    final imageController =
        TextEditingController(text: data?['imageUrl'] as String? ?? '');
    final orderController =
        TextEditingController(text: (data?['order'] ?? '').toString());
    var useColor = (data?['colorHex'] as String? ?? '').isNotEmpty;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(docId == null ? '배너 추가' : '배너 수정'),
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
                      seedController: titleController,
                      prefix: 'banner',
                    ),
                    AdminTextField(label: '제목', controller: titleController),
                    AdminTextField(
                      label: '부제목',
                      controller: subtitleController,
                      maxLines: 2,
                    ),
                    AdminTextField(
                      label: '순서',
                      controller: orderController,
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      value: useColor,
                      onChanged: (value) => setState(() => useColor = value),
                      title: const Text('배경색 사용'),
                    ),
                    if (useColor)
                      AdminTextField(
                        label: '색상(HEX)',
                        controller: colorController,
                      ),
                    if (useColor)
                      ColorPickerRow(
                        controller: colorController,
                        colors: const [
                          Color(0xFF8E99F3),
                          Color(0xFF26C6DA),
                          Color(0xFFFFB74D),
                          Color(0xFF90CAF9),
                          Color(0xFFA5D6A7),
                        ],
                      ),
                    const SizedBox(height: 8),
                    ImageUploadField(
                      label: '이미지 URL',
                      controller: imageController,
                      helperText: '배너 배경 이미지',
                      storagePath: 'banners',
                      onSaved: docId == null
                          ? null
                          : (value) => _collection()
                              .doc(docId)
                              .set({'imageUrl': value}, SetOptions(merge: true)),
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
      'title': titleController.text.trim(),
      'subtitle': subtitleController.text.trim(),
      'imageUrl': imageController.text.trim(),
    };
    if (useColor) {
      payload['colorHex'] = colorController.text.trim();
    } else if (docId != null) {
      payload['colorHex'] = FieldValue.delete();
    }
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
      appBar: AppBar(title: const Text('배너 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBannerDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collection().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '배너를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 배너가 없습니다.'));
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
              final titleA = dataA['title'] as String? ?? a.id;
              final titleB = dataB['title'] as String? ?? b.id;
              return titleA.compareTo(titleB);
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
                  title: Text(data['title'] as String? ?? doc.id),
                  subtitle: Text(
                    '${data['subtitle'] as String? ?? ''} · 순서: $orderText',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBannerDialog(
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
