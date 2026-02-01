import 'package:my_ebook/models/business_page.dart';

class Business {
  const Business({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.summary,
    required this.phone,
    required this.address,
    required this.order,
    required this.pages,
    required this.tags,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.closedDays,
    this.instagramUrl,
    this.blogUrl,
    this.kakaoChannelUrl,
    this.websiteUrl,
    this.couponImageUrl,
  });

  final String id;
  final String categoryId;
  final String name;
  final String summary;
  final String phone;
  final String address;
  final int order;
  final List<BusinessPage> pages;
  final List<String> tags;
  final String? thumbnailUrl;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final String? closedDays;
  final String? instagramUrl;
  final String? blogUrl;
  final String? kakaoChannelUrl;
  final String? websiteUrl;
  final String? couponImageUrl;
}
