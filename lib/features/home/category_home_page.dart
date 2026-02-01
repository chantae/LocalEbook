import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_ebook/app/app.dart';
import 'package:my_ebook/core/debug_log.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/features/business_detail/business_detail_page.dart';
import 'package:my_ebook/features/category_list/category_list_page.dart';
import 'package:my_ebook/models/banner_item.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/business_page.dart';
import 'package:my_ebook/models/category.dart';
import 'package:my_ebook/services/firestore_service.dart';
import 'package:my_ebook/widgets/account_menu_button.dart';
import 'package:my_ebook/widgets/banner/banner_slider.dart';

class CategoryHomePage extends StatefulWidget {
  const CategoryHomePage({super.key});

  @override
  State<CategoryHomePage> createState() => _CategoryHomePageState();
}

class _CategoryHomePageState extends State<CategoryHomePage> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  static bool _seededOnce = false;
  bool _sortByDistance = false;
  bool _isLocating = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _seedFirestoreIfNeeded();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (_searchQuery != next) {
        setState(() => _searchQuery = next);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty) {
      _searchController.clear();
      setState(() => _searchQuery = '');
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleSortByDistance() async {
    final next = !_sortByDistance;
    if (!next) {
      setState(() => _sortByDistance = false);
      return;
    }
    if (_isLocating) {
      return;
    }
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 서비스가 꺼져 있습니다.')),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 필요합니다.')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPosition = position;
        _sortByDistance = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  List<Category> _buildCategories() {
    return const [
      Category(
        id: 'food',
        name: '음식점',
        color: Color(0xFFE57373),
        icon: Icons.restaurant,
        order: 1,
        imageUrl: null,
      ),
      Category(
        id: 'beauty',
        name: '뷰티',
        color: Color(0xFFF06292),
        icon: Icons.spa,
        order: 2,
        imageUrl: null,
      ),
      Category(
        id: 'fitness',
        name: '운동',
        color: Color(0xFF64B5F6),
        icon: Icons.fitness_center,
        order: 3,
        imageUrl: null,
      ),
      Category(
        id: 'academy',
        name: '학원',
        color: Color(0xFF4DB6AC),
        icon: Icons.school,
        order: 4,
        imageUrl: null,
      ),
      Category(
        id: 'hobby',
        name: '취미',
        color: Color(0xFFFFB74D),
        icon: Icons.palette,
        order: 5,
        imageUrl: null,
      ),
      Category(
        id: 'cafe',
        name: '카페',
        color: Color(0xFF8D6E63),
        icon: Icons.local_cafe,
        order: 6,
        imageUrl: null,
      ),
      Category(
        id: 'hospital',
        name: '병원',
        color: Color(0xFF81C784),
        icon: Icons.local_hospital,
        order: 7,
        imageUrl: null,
      ),
      Category(
        id: 'service',
        name: '전문가 서비스',
        color: Color(0xFF9575CD),
        icon: Icons.support_agent,
        order: 8,
        imageUrl: null,
      ),
    ];
  }

  Future<void> _seedFirestoreIfNeeded() async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    if (_seededOnce) {
      return;
    }
    _seededOnce = true;
    final firestore = FirebaseFirestore.instance;
    final check = await firestore.collection('categories').limit(1).get();
    if (check.docs.isNotEmpty) {
      return;
    }

    final categories = _buildCategories();
    final businesses = _buildSeedBusinesses(categories);
    final batch = firestore.batch();

    for (final category in categories) {
      batch.set(
        firestore.collection('categories').doc(category.id),
        {
          'name': category.name,
          'colorHex': hexFromColor(category.color),
          'icon': iconNameFromIcon(category.icon),
          'order': category.order,
          'imageUrl': category.imageUrl ?? '',
        },
      );
    }

    for (var i = 0; i < defaultBanners.length; i++) {
      final banner = defaultBanners[i];
      final bannerColor = banner.color;
      batch.set(
        firestore.collection('banners').doc('banner_${i + 1}'),
        {
          'title': banner.title,
          'subtitle': banner.subtitle,
          'colorHex': bannerColor == null ? '' : hexFromColor(bannerColor),
          'order': banner.order,
          'imageUrl': banner.imageUrl ?? '',
        },
      );
    }

    for (final business in businesses) {
      batch.set(
        firestore.collection('businesses').doc(business.id),
        {
          'categoryId': business.categoryId,
          'name': business.name,
          'summary': business.summary,
          'phone': business.phone,
          'address': business.address,
          'order': business.order,
          'tags': business.tags,
          'thumbnailUrl': business.thumbnailUrl ?? '',
          'latitude': business.latitude,
          'longitude': business.longitude,
          'openingHours': business.openingHours ?? '',
          'closedDays': business.closedDays ?? '',
          'instagramUrl': business.instagramUrl ?? '',
          'blogUrl': business.blogUrl ?? '',
          'kakaoChannelUrl': business.kakaoChannelUrl ?? '',
          'websiteUrl': business.websiteUrl ?? '',
          'couponImageUrl': business.couponImageUrl ?? '',
        },
      );
      for (final page in business.pages) {
        batch.set(
          firestore.collection('business_pages').doc(page.id),
          {
            'businessId': page.businessId,
            'label': page.label,
            'colorHex': hexFromColor(page.color),
            'order': page.order,
            'imageUrl': page.imageUrl ?? '',
          },
        );
      }
    }

    await batch.commit();
  }

  List<Business> _buildSeedBusinesses(List<Category> categories) {
    return categories.expand((category) {
      return List.generate(6, (index) {
        final number = index + 1;
        final businessId = '${category.id}_$number';
        return Business(
          id: businessId,
          categoryId: category.id,
          name: '${category.name} 업체 $number',
          summary: '간단한 소개 문구를 입력하세요.',
          phone: '02-000$number-000$number',
          address: '서울시 로컬구 로컬로 $number',
          order: number,
          pages: [
            BusinessPage(
              id: '${businessId}_intro',
              businessId: businessId,
              label: '${category.name} 업체 $number 소개',
              color: category.color,
              order: 1,
              imageUrl: null,
            ),
            BusinessPage(
              id: '${businessId}_service',
              businessId: businessId,
              label: '${category.name} 업체 $number 서비스',
              color: category.color.withOpacity(0.85),
              order: 2,
              imageUrl: null,
            ),
            BusinessPage(
              id: '${businessId}_info',
              businessId: businessId,
              label: '${category.name} 업체 $number 안내',
              color: category.color.withOpacity(0.7),
              order: 3,
              imageUrl: null,
            ),
          ],
          tags: [category.name],
          thumbnailUrl: null,
          latitude: null,
          longitude: null,
          openingHours: '10:00 - 22:00',
          closedDays: '매주 월요일',
          instagramUrl: '',
          blogUrl: '',
          kakaoChannelUrl: '',
          websiteUrl: '',
          couponImageUrl: '',
        );
      });
    }).toList();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final localCategories = _buildCategories();
    final localBusinesses = _buildSeedBusinesses(localCategories);
    final screenWidth = MediaQuery.of(context).size.width;
    debugLog(
      location: 'category_home_page.dart:CategoryHomePage.build',
      message: 'layout metrics',
      data: {'width': screenWidth},
      hypothesisId: 'H2',
    );
    final horizontalPadding = screenWidth >= 900 ? screenWidth * 0.15 : 12.0;
    return Scaffold(
      appBar: AppBar(
        leading: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: tryGetFirestoreService() == null
              ? null
              : FirebaseFirestore.instance
                  .collection('admin_settings')
                  .doc('config')
                  .snapshots(),
          builder: (context, snapshot) {
            final iconUrl =
                snapshot.data?.data()?['mainIconImageUrl'] as String? ?? '';
            final iconName =
                snapshot.data?.data()?['mainIcon'] as String? ?? 'tag';
            if (iconUrl.trim().isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(6),
                child: ClipOval(
                  child: Image.network(
                    iconUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(iconFromName(iconName, Icons.tag)),
                  ),
                ),
              );
            }
            return Icon(iconFromName(iconName, Icons.tag));
          },
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '업체 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '내 주변 정렬',
            icon: Icon(
              _sortByDistance ? Icons.my_location : Icons.location_on_outlined,
            ),
            onPressed: _toggleSortByDistance,
          ),
          const AccountMenuButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
          child: StreamBuilder<List<Category>>(
            stream: tryGetFirestoreService()?.watchCategories(localCategories) ??
                Stream.value(localCategories),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugLog(
                  location: 'category_home_page.dart:categories.stream',
                  message: 'categories stream error',
                  data: {'error': snapshot.error.toString()},
                  hypothesisId: 'H3',
                );
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '카테고리를 불러오지 못했습니다.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              final categories = snapshot.data?.isNotEmpty == true
                  ? snapshot.data!
                  : localCategories;
              final categoryMap = {
                for (final category in categories) category.id: category,
              };
              return StreamBuilder<List<BannerItem>>(
                stream:
                    tryGetFirestoreService()?.watchBanners(defaultBanners) ??
                        Stream.value(defaultBanners),
                builder: (context, bannerSnapshot) {
                  if (bannerSnapshot.hasError) {
                    debugLog(
                      location: 'category_home_page.dart:banners.stream',
                      message: 'banners stream error',
                      data: {'error': bannerSnapshot.error.toString()},
                      hypothesisId: 'H3',
                    );
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '배너를 불러오지 못했습니다.\n${bannerSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                  final banners = bannerSnapshot.data?.isNotEmpty == true
                      ? bannerSnapshot.data!
                      : defaultBanners;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 2.0;
                      final width = constraints.maxWidth;
                      final crossAxisCount =
                          width < 520 ? 4 : (width < 820 ? 5 : 6);
                      final blockSize = (width -
                              spacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                      final bannerHeight = blockSize * 1.6 + spacing;

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_searchQuery.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SearchResults(
                                query: _searchQuery,
                                localBusinesses: localBusinesses,
                                categoryMap: categoryMap,
                                sortByDistance: _sortByDistance,
                                position: _currentPosition,
                              ),
                            ),
                          if (_searchQuery.isNotEmpty)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: spacing),
                            ),
                          if (_searchQuery.isEmpty)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: bannerHeight,
                                child: BannerSlider(banners: banners),
                              ),
                            ),
                          if (_searchQuery.isEmpty)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: spacing),
                            ),
                          if (_searchQuery.isEmpty)
                            SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: 1,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final category = categories[index];
                                  return _CategoryCard(
                                    category: category,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CategoryListPage(
                                            category: category,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: categories.length,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: category.color.withOpacity(0.15),
                  backgroundImage: category.imageUrl != null &&
                          category.imageUrl!.trim().isNotEmpty
                      ? NetworkImage(category.imageUrl!)
                      : null,
                  child: category.imageUrl != null &&
                          category.imageUrl!.trim().isNotEmpty
                      ? null
                      : Icon(
                          category.icon,
                          size: 22,
                          color: category.color,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.localBusinesses,
    required this.categoryMap,
    required this.sortByDistance,
    required this.position,
  });

  final String query;
  final List<Business> localBusinesses;
  final Map<String, Category> categoryMap;
  final bool sortByDistance;
  final Position? position;

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.trim().toLowerCase();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxItems = screenHeight < 700
        ? 3
        : (screenHeight < 900 ? 4 : 5);
    return StreamBuilder<List<Business>>(
      stream: tryGetFirestoreService()?.watchAllBusinesses(localBusinesses) ??
          Stream.value(localBusinesses),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '검색 결과를 불러오지 못했습니다.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        final businesses = snapshot.data ?? localBusinesses;
        final filtered = businesses.where((business) {
          final haystack = [
            business.name,
            business.summary,
            business.phone,
            business.address,
            business.tags.join(' '),
          ].join(' ').toLowerCase();
          return haystack.contains(lowerQuery);
        }).toList();
        if (sortByDistance && position != null) {
          filtered.sort((a, b) {
            final aLat = a.latitude;
            final aLng = a.longitude;
            final bLat = b.latitude;
            final bLng = b.longitude;
            final aDistance = (aLat == null || aLng == null)
                ? double.infinity
                : Geolocator.distanceBetween(
                    position!.latitude,
                    position!.longitude,
                    aLat,
                    aLng,
                  );
            final bDistance = (bLat == null || bLng == null)
                ? double.infinity
                : Geolocator.distanceBetween(
                    position!.latitude,
                    position!.longitude,
                    bLat,
                    bLng,
                  );
            return aDistance.compareTo(bDistance);
          });
        }
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '검색 결과가 없습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final visible = filtered.length > maxItems
            ? filtered.take(maxItems).toList()
            : filtered;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '검색 결과',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final business = visible[index];
                final category = categoryMap[business.categoryId] ??
                    Category(
                      id: business.categoryId,
                      name: business.categoryId.isEmpty
                          ? '기타'
                          : business.categoryId,
                      color: Colors.blueGrey,
                      icon: Icons.tag,
                      order: 9999,
                      imageUrl: null,
                    );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(business.name),
                  subtitle: Text(
                    '${category.name} · ${business.address}',
                    maxLines: 1,
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
                );
              },
            ),
          ],
        );
      },
    );
  }
}

const defaultBanners = [
  BannerItem(
    title: '로컬 광고 배너',
    subtitle: '지역 업체의 프로모션을 확인하세요',
    color: Color(0xFF8E99F3),
    order: 1,
    imageUrl: null,
  ),
  BannerItem(
    title: '신규 입점 이벤트',
    subtitle: '새로운 업체 혜택을 만나보세요',
    color: Color(0xFF26C6DA),
    order: 2,
    imageUrl: null,
  ),
  BannerItem(
    title: '한정 기간 할인',
    subtitle: '이번 주 특가를 놓치지 마세요',
    color: Color(0xFFFFB74D),
    order: 3,
    imageUrl: null,
  ),
];
