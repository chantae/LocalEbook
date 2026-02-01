import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/debug_log.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/models/banner_item.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/business_page.dart';
import 'package:my_ebook/models/category.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Category>> watchCategories(List<Category> fallback) {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      final baseMap = {for (final item in fallback) item.id: item};
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final base = baseMap[doc.id];
        return Category(
          id: doc.id,
          name: data['name'] as String? ?? base?.name ?? doc.id,
          color: colorFromHex(
            data['colorHex'] as String?,
            base?.color ?? Colors.blueGrey,
          ),
          icon: iconFromName(data['icon'] as String?, base?.icon ?? Icons.tag),
          order: orderValue(data['order'], base?.order ?? 9999),
          imageUrl: data['imageUrl'] as String? ?? base?.imageUrl,
        );
      }).toList();
      items.sort((a, b) {
        final compare = a.order.compareTo(b.order);
        if (compare != 0) {
          return compare;
        }
        return a.name.compareTo(b.name);
      });
      return items;
    });
  }

  Stream<List<BannerItem>> watchBanners(List<BannerItem> fallback) {
    return _firestore.collection('banners').snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final colorHex = data['colorHex'] as String?;
        return BannerItem(
          title: data['title'] as String? ?? '프로모션',
          subtitle: data['subtitle'] as String? ?? '배너 문구를 입력하세요',
          color: colorHex == null || colorHex.trim().isEmpty
              ? null
              : colorFromHex(colorHex, Colors.blueGrey),
          order: orderValue(data['order'], 9999),
          imageUrl: data['imageUrl'] as String?,
        );
      }).toList();
      items.sort((a, b) {
        final compare = a.order.compareTo(b.order);
        if (compare != 0) {
          return compare;
        }
        return a.title.compareTo(b.title);
      });
      return items;
    });
  }

  Stream<List<Business>> watchBusinesses(
    String categoryId,
    List<Business> fallback,
  ) {
    return _firestore
        .collection('businesses')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawTags = data['tags'];
        final tags = rawTags is List
            ? rawTags
                .whereType<String>()
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toSet()
                .toList()
            : rawTags is String
                ? parseTagsInput(rawTags)
                : const <String>[];
        return Business(
          id: doc.id,
          categoryId: categoryId,
          name: data['name'] as String? ?? doc.id,
          summary: data['summary'] as String? ?? '간단한 소개 문구를 입력하세요.',
          phone: data['phone'] as String? ?? '',
          address: data['address'] as String? ?? '',
          order: orderValue(data['order'], 9999),
          pages: const [],
          tags: tags,
          thumbnailUrl: data['thumbnailUrl'] as String?,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          openingHours: data['openingHours'] as String?,
          closedDays: data['closedDays'] as String?,
          instagramUrl: data['instagramUrl'] as String?,
          blogUrl: data['blogUrl'] as String?,
          kakaoChannelUrl: data['kakaoChannelUrl'] as String?,
          websiteUrl: data['websiteUrl'] as String?,
          couponImageUrl: data['couponImageUrl'] as String?,
        );
      }).toList();
      items.sort((a, b) {
        final compare = a.order.compareTo(b.order);
        if (compare != 0) {
          return compare;
        }
        return a.name.compareTo(b.name);
      });
      return items;
    });
  }

  Stream<List<Business>> watchAllBusinesses(List<Business> fallback) {
    return _firestore.collection('businesses').snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawTags = data['tags'];
        final tags = rawTags is List
            ? rawTags
                .whereType<String>()
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toSet()
                .toList()
            : rawTags is String
                ? parseTagsInput(rawTags)
                : const <String>[];
        return Business(
          id: doc.id,
          categoryId: data['categoryId'] as String? ?? '',
          name: data['name'] as String? ?? doc.id,
          summary: data['summary'] as String? ?? '간단한 소개 문구를 입력하세요.',
          phone: data['phone'] as String? ?? '',
          address: data['address'] as String? ?? '',
          order: orderValue(data['order'], 9999),
          pages: const [],
          tags: tags,
          thumbnailUrl: data['thumbnailUrl'] as String?,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          openingHours: data['openingHours'] as String?,
          closedDays: data['closedDays'] as String?,
          instagramUrl: data['instagramUrl'] as String?,
          blogUrl: data['blogUrl'] as String?,
          kakaoChannelUrl: data['kakaoChannelUrl'] as String?,
          websiteUrl: data['websiteUrl'] as String?,
          couponImageUrl: data['couponImageUrl'] as String?,
        );
      }).toList();
      items.sort((a, b) {
        final compare = a.order.compareTo(b.order);
        if (compare != 0) {
          return compare;
        }
        return a.name.compareTo(b.name);
      });
      return items.isNotEmpty ? items : fallback;
    });
  }

  Stream<List<BusinessPage>> watchBusinessPages(
    String businessId,
    Color fallbackColor,
  ) {
    return _firestore
        .collection('business_pages')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return BusinessPage(
          id: doc.id,
          businessId: businessId,
          label: data['label'] as String? ?? '업체 안내',
          color: colorFromHex(data['colorHex'] as String?, fallbackColor),
          order: orderValue(data['order'], 9999),
          imageUrl: data['imageUrl'] as String?,
        );
      }).toList();
      items.sort((a, b) {
        final compare = a.order.compareTo(b.order);
        if (compare != 0) {
          return compare;
        }
        return a.label.compareTo(b.label);
      });
      return items;
    });
  }
}

FirestoreService? _firestoreServiceInstance;

FirestoreService? tryGetFirestoreService() {
  debugLog(
    location: 'firestore_service.dart:tryGetFirestoreService',
    message: 'check firebase apps',
    data: {'apps': Firebase.apps.length},
    hypothesisId: 'H1',
  );
  if (Firebase.apps.isEmpty) {
    return null;
  }
  return _firestoreServiceInstance ??= FirestoreService();
}
