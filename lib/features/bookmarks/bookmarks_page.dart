import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/category.dart';
import 'package:my_ebook/services/firestore_service.dart';
import 'package:my_ebook/features/business_detail/business_detail_page.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('찜한 업체')),
        body: const Center(child: Text('로그인 후 이용할 수 있습니다.')),
      );
    }
    final bookmarkStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text('찜한 업체')),
      body: StreamBuilder<List<Category>>(
        stream: tryGetFirestoreService()?.watchCategories(const []) ??
            Stream.value(const []),
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? const [];
          final categoryMap = {
            for (final item in categories) item.id: item,
          };
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: bookmarkStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('찜한 업체가 없습니다.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final categoryId = data['categoryId'] as String? ?? '';
                  final category = categoryMap[categoryId] ??
                      Category(
                        id: categoryId,
                        name: categoryId.isEmpty ? '기타' : categoryId,
                        color: Colors.blueGrey,
                        icon: Icons.storefront,
                        order: 9999,
                        imageUrl: null,
                      );
                  final business = Business(
                    id: data['businessId'] as String? ?? '',
                    categoryId: categoryId,
                    name: data['name'] as String? ?? '업체',
                    summary: data['summary'] as String? ?? '',
                    phone: data['phone'] as String? ?? '',
                    address: data['address'] as String? ?? '',
                    order: 0,
                    pages: const [],
                    tags: const [],
                    thumbnailUrl: data['thumbnailUrl'] as String?,
                    latitude: null,
                    longitude: null,
                    openingHours: null,
                    closedDays: null,
                    instagramUrl: null,
                    blogUrl: null,
                    kakaoChannelUrl: null,
                    websiteUrl: null,
                    couponImageUrl: null,
                  );
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: _ThumbnailPreview(url: business.thumbnailUrl),
                      title: Text(business.name),
                      subtitle: Text(
                        business.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessDetailPage(
                              category: category,
                              business: business,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.storefront));
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(trimmed),
      onBackgroundImageError: (_, __) {},
    );
  }
}
