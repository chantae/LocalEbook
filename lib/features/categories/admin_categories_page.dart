import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/widgets/admin_fields.dart';
import 'package:my_ebook/widgets/color_picker_row.dart';
import 'package:my_ebook/widgets/image_upload_field.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance.collection('categories');
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

  Future<void> _showCategoryDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    final idController = TextEditingController(text: docId ?? '');
    final nameController =
        TextEditingController(text: data?['name'] as String? ?? '');
    final colorController =
        TextEditingController(text: data?['colorHex'] as String? ?? '#90CAF9');
    final iconController =
        TextEditingController(text: data?['icon'] as String? ?? 'tag');
    final imageController =
        TextEditingController(text: data?['imageUrl'] as String? ?? '');
    final orderController =
        TextEditingController(text: (data?['order'] ?? '').toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? '카테고리 추가' : '카테고리 수정'),
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
                  prefix: 'cat',
                ),
                AdminTextField(label: '이름', controller: nameController),
                AdminTextField(
                  label: '순서',
                  controller: orderController,
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: iconController.text.isEmpty
                      ? null
                      : iconController.text,
                  decoration: const InputDecoration(
                    labelText: '아이콘',
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
                    iconController.text = value ?? 'tag';
                  },
                ),
                const SizedBox(height: 8),
                AdminTextField(label: '색상(HEX)', controller: colorController),
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
                const SizedBox(height: 8),
                ImageUploadField(
                  label: '카테고리 이미지 URL',
                  controller: imageController,
                  helperText: '카테고리 아이콘 이미지',
                  storagePath: 'categories',
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

    if (result != true) {
      return;
    }

    final id = idController.text.trim();
    if (id.isEmpty) {
      return;
    }

    final payload = <String, Object?>{
      'name': nameController.text.trim(),
      'colorHex': colorController.text.trim(),
      'icon': iconController.text.trim(),
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
      appBar: AppBar(title: const Text('카테고리 관리')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collection().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '카테고리를 불러오지 못했습니다.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('등록된 카테고리가 없습니다.'));
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
                  title: Text('${data['name'] ?? doc.id}'),
                  subtitle: Text('ID: ${doc.id} · 순서: $orderText'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showCategoryDialog(
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
