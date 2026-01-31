import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/business_page.dart';
import 'package:my_ebook/models/category.dart';
import 'package:my_ebook/services/firestore_service.dart';
import 'package:my_ebook/widgets/account_menu_button.dart';

class BusinessDetailPage extends StatefulWidget {
  const BusinessDetailPage({
    super.key,
    required this.category,
    required this.business,
  });

  final Category category;
  final Business business;

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _goToPage(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goNext(int totalPages) {
    if (_pageIndex >= totalPages - 1) {
      return;
    }
    _goToPage(_pageIndex + 1);
  }

  void _goPrevious() {
    if (_pageIndex <= 0) {
      return;
    }
    _goToPage(_pageIndex - 1);
  }

  void _showImageFullScreen(String? imageUrl) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }

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

  List<Business> _buildBusinesses() {
    final category = widget.category;
    return List.generate(6, (index) {
      final number = index + 1;
      return Business(
        id: '${category.id}_$number',
        categoryId: category.id,
        name: '${category.name} 업체 $number',
        summary: '간단한 소개 문구를 입력하세요.',
        phone: '02-000$number-000$number',
        address: '서울시 로컬구 로컬로 $number',
        order: number,
        pages: const [],
        tags: [category.name],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final fallbackPages = business.pages;
    final localBusinesses = _buildBusinesses();
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
        actions: const [AccountMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _searchQuery.isNotEmpty
            ? _CategorySearchResults(
                query: _searchQuery,
                category: widget.category,
                localBusinesses: localBusinesses,
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        business.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: StreamBuilder<List<BusinessPage>>(
                      stream: tryGetFirestoreService()?.watchBusinessPages(
                            business.id,
                            widget.category.color,
                          ) ??
                          Stream.value(fallbackPages),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '업체 페이지를 불러오지 못했습니다.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final pages = snapshot.data?.isNotEmpty == true
                            ? snapshot.data!
                            : fallbackPages;
                        if (pages.isEmpty) {
                          return Center(
                            child: Text(
                              '등록된 업체 페이지가 없습니다.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }
                        if (_pageIndex >= pages.length) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _pageIndex = 0);
                            }
                          });
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    controller: _controller,
                                    itemCount: pages.length,
                                    onPageChanged: (index) =>
                                        setState(() => _pageIndex = index),
                                    itemBuilder: (context, index) {
                                      final page = pages[index];
                                      return Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: _GeneratedImageCard(
                                          label: page.label,
                                          color: page.color,
                                          imageUrl: page.imageUrl,
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: _goPrevious,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: () => _showImageFullScreen(
                                              pages[_pageIndex].imageUrl,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: () => _goNext(pages.length),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${_pageIndex + 1} / ${pages.length}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _searchQuery.isNotEmpty
          ? null
          : _BusinessFooter(
              name: business.name,
              phone: business.phone,
              address: business.address,
            ),
    );
  }
}

class _GeneratedImageCard extends StatelessWidget {
  const _GeneratedImageCard({
    required this.label,
    required this.color,
    this.imageUrl,
  });

  final String label;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.5),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.trim().isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessFooter extends StatelessWidget {
  const _BusinessFooter({
    required this.name,
    required this.phone,
    required this.address,
  });

  final String name;
  final String phone;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('전화번호: $phone', style: theme.textTheme.bodySmall),
            Text('주소: $address', style: theme.textTheme.bodySmall),
          ],
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
