import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/debug_log.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/features/business_detail/business_detail_page.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/business_page.dart';
import 'package:my_ebook/models/category.dart';
import 'package:my_ebook/services/firestore_service.dart';
import 'package:my_ebook/widgets/account_menu_button.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key, required this.category});

  final Category category;

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _useTileView = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (_searchQuery != next) {
        setState(() => _searchQuery = next);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  List<Business> _buildBusinesses() {
    return List.generate(6, (index) {
      final number = index + 1;
      final category = widget.category;
      return Business(
        id: '${category.id}_$number',
        categoryId: category.id,
        name: '${category.name} 업체 $number',
        summary: '간단한 소개 문구를 입력하세요.',
        phone: '02-000$number-000$number',
        address: '서울시 로컬구 로컬로 $number',
        order: number,
        pages: [
          BusinessPage(
            id: '${category.id}_${number}_intro',
            businessId: '${category.id}_$number',
            label: '${category.name} 업체 $number 소개',
            color: category.color,
            order: 1,
          ),
          BusinessPage(
            id: '${category.id}_${number}_service',
            businessId: '${category.id}_$number',
            label: '${category.name} 업체 $number 서비스',
            color: category.color.withOpacity(0.85),
            order: 2,
          ),
          BusinessPage(
            id: '${category.id}_${number}_info',
            businessId: '${category.id}_$number',
            label: '${category.name} 업체 $number 안내',
            color: category.color.withOpacity(0.7),
            order: 3,
          ),
        ],
        tags: [category.name],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localBusinesses = _buildBusinesses();
    final category = widget.category;
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
            return IconButton(
              tooltip: '홈',
              icon: iconUrl.trim().isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        iconUrl,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(iconFromName(iconName, Icons.tag)),
                      ),
                    )
                  : Icon(iconFromName(iconName, Icons.tag)),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            );
          },
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '검색',
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
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _useTileView ? '리스트 보기' : '타일 보기',
            icon: Icon(_useTileView ? Icons.view_list : Icons.grid_view_rounded),
            onPressed: () => setState(() => _useTileView = !_useTileView),
          ),
          const AccountMenuButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _searchQuery.isNotEmpty
            ? _CategorySearchResults(
                query: _searchQuery,
                category: category,
                localBusinesses: localBusinesses,
              )
            : StreamBuilder<List<Business>>(
                stream: tryGetFirestoreService()?.watchBusinesses(
                      category.id,
                      localBusinesses,
                    ) ??
                    Stream.value(localBusinesses),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugLog(
                      location: 'category_list_page.dart:businesses.stream',
                      message: 'businesses stream error',
                      data: {'error': snapshot.error.toString()},
                      hypothesisId: 'H3',
                    );
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '업체를 불러오지 못했습니다.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }
                  final businesses = snapshot.data?.isNotEmpty == true
                      ? snapshot.data!
                      : localBusinesses;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (_useTileView) {
                        final width = constraints.maxWidth;
                        final crossAxisCount =
                            width < 520 ? 2 : (width < 900 ? 3 : 4);
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: businesses.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder: (context, index) {
                            final business = businesses[index];
                            return _BusinessCardTypeTile(
                              business: business,
                              color: category.color,
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
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: businesses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final business = businesses[index];
                          return _BusinessCardTypeList(
                            business: business,
                            color: category.color,
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
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _CategorySearchResults extends StatelessWidget {
  const _CategorySearchResults({
    required this.query,
    required this.category,
    required this.localBusinesses,
  });

  final String query;
  final Category category;
  final List<Business> localBusinesses;

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.trim().toLowerCase();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxItems = screenHeight < 700
        ? 3
        : (screenHeight < 900 ? 4 : 5);
    return StreamBuilder<List<Category>>(
      stream: tryGetFirestoreService()?.watchCategories([category]) ??
          Stream.value([category]),
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data?.isNotEmpty == true
            ? categorySnapshot.data!
            : [category];
        final categoryMap = {
          for (final item in categories) item.id: item,
        };
        return StreamBuilder<List<Business>>(
          stream: tryGetFirestoreService()?.watchAllBusinesses(
                localBusinesses,
              ) ??
              Stream.value(localBusinesses),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
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
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
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
                    final resultCategory =
                        categoryMap[business.categoryId] ?? category;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(business.name),
                      subtitle: Text(
                        '${resultCategory.name} · ${business.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BusinessDetailPage(
                              category: resultCategory,
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
      },
    );
  }
}

class _BusinessCardTypeList extends StatelessWidget {
  const _BusinessCardTypeList({
    required this.business,
    required this.color,
    required this.onTap,
  });

  final Business business;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = constraints.maxWidth * 0.25;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          business.summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          business.address,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          business.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: imageWidth,
                    height: imageWidth * 0.75,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.85),
                          color.withOpacity(0.55),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BusinessCardTypeTile extends StatelessWidget {
  const _BusinessCardTypeTile({
    required this.business,
    required this.color,
    required this.onTap,
  });

  final Business business;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.85),
                        color.withOpacity(0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.image_outlined, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                business.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                business.summary,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                business.address,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
