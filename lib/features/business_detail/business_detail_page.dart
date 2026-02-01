import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_ebook/core/utils.dart';
import 'package:my_ebook/models/business.dart';
import 'package:my_ebook/models/business_page.dart';
import 'package:my_ebook/models/category.dart';
import 'package:my_ebook/services/firestore_service.dart';
import 'package:my_ebook/widgets/account_menu_button.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _didLogView = false;

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
    _logViewOnce();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (_searchQuery != next) {
        setState(() => _searchQuery = next);
      }
    });
  }

  Future<void> _logViewOnce() async {
    if (_didLogView) {
      return;
    }
    _didLogView = true;
    await _incrementMetric('viewCount');
  }

  Future<void> _incrementMetric(String field) async {
    final businessId = widget.business.id;
    await FirebaseFirestore.instance
        .collection('business_metrics')
        .doc(businessId)
        .set({field: FieldValue.increment(1)}, SetOptions(merge: true));
  }

  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) {
      return;
    }
    await _incrementMetric('phoneClickCount');
    final uri = Uri.parse('tel:$cleaned');
    await launchUrl(uri);
  }

  Future<void> _launchLink(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final uri = Uri.parse(trimmed);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _kakaoMapUrl(Business business) {
    final lat = business.latitude;
    final lng = business.longitude;
    final name = Uri.encodeComponent(business.name);
    if (lat != null && lng != null) {
      return 'https://map.kakao.com/link/map/$name,$lat,$lng';
    }
    return 'https://map.kakao.com/link/search/$name';
  }

  String _naverMapUrl(Business business) {
    final lat = business.latitude;
    final lng = business.longitude;
    final name = Uri.encodeComponent(business.name);
    if (lat != null && lng != null) {
      return 'https://map.naver.com/v5/search/$name?c=$lng,$lat,15,0,0,0,dh';
    }
    return 'https://map.naver.com/v5/search/$name';
  }

  Future<void> _toggleBookmark(Business business) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용할 수 있습니다.')),
      );
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(business.id);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'businessId': business.id,
        'categoryId': business.categoryId,
        'name': business.name,
        'summary': business.summary,
        'phone': business.phone,
        'address': business.address,
        'thumbnailUrl': business.thumbnailUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _toggleLike(Business business) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용할 수 있습니다.')),
      );
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('businesses')
        .doc(business.id)
        .collection('likes')
        .doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _BusinessEngagementRow(
                        business: business,
                        onBookmark: () => _toggleBookmark(business),
                        onLike: () => _toggleLike(business),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
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
                        final sliderHeight =
                            MediaQuery.of(context).size.height * 0.55;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: sliderHeight,
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
                              child: Center(
                                child: Text(
                                  '${_pageIndex + 1} / ${pages.length}',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _BusinessInfoSection(
                                business: business,
                                onPhoneTap: () => _launchPhone(business.phone),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _BusinessMapSection(
                                business: business,
                                onOpenKakao: () =>
                                    _launchLink(_kakaoMapUrl(business)),
                                onOpenNaver: () =>
                                    _launchLink(_naverMapUrl(business)),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _BusinessLinksSection(
                                business: business,
                                onOpenLink: _launchLink,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _BusinessCouponSection(
                                business: business,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _BusinessNewsSection(
                                businessId: business.id,
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
              onPhoneTap: () => _launchPhone(business.phone),
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
    required this.onPhoneTap,
  });

  final String name;
  final String phone;
  final String address;
  final VoidCallback onPhoneTap;

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
            GestureDetector(
              onTap: onPhoneTap,
              child: Text(
                '전화번호: $phone',
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text('주소: $address', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BusinessEngagementRow extends StatelessWidget {
  const _BusinessEngagementRow({
    required this.business,
    required this.onBookmark,
    required this.onLike,
  });

  final Business business;
  final VoidCallback onBookmark;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final authStream = FirebaseAuth.instance.authStateChanges();
    return StreamBuilder<User?>(
      stream: authStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final bookmarkStream = user == null
            ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
            : FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('bookmarks')
                .doc(business.id)
                .snapshots();
        final likeStream = FirebaseFirestore.instance
            .collection('businesses')
            .doc(business.id)
            .collection('likes')
            .snapshots();
        return Row(
          children: [
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: bookmarkStream,
                builder: (context, snapshot) {
                  final isBookmarked = snapshot.data?.exists == true;
                  return OutlinedButton.icon(
                    onPressed: onBookmark,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(isBookmarked ? '찜됨' : '찜하기'),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: likeStream,
                builder: (context, snapshot) {
                  final likeCount = snapshot.data?.docs.length ?? 0;
                  return OutlinedButton.icon(
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite_border),
                    label: Text('좋아요 $likeCount'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BusinessInfoSection extends StatelessWidget {
  const _BusinessInfoSection({
    required this.business,
    required this.onPhoneTap,
  });

  final Business business;
  final VoidCallback onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final opening = business.openingHours?.trim() ?? '';
    final closed = business.closedDays?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('업체 정보', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(business.summary, style: textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.phone, size: 18),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPhoneTap,
              child: Text(
                business.phone,
                style: textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                business.address,
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (opening.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 8),
              Text(opening, style: textTheme.bodySmall),
            ],
          ),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_busy, size: 18),
              const SizedBox(width: 8),
              Text(closed, style: textTheme.bodySmall),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BusinessMapSection extends StatelessWidget {
  const _BusinessMapSection({
    required this.business,
    required this.onOpenKakao,
    required this.onOpenNaver,
  });

  final Business business;
  final VoidCallback onOpenKakao;
  final VoidCallback onOpenNaver;

  @override
  Widget build(BuildContext context) {
    final lat = business.latitude;
    final lng = business.longitude;
    if (lat == null || lng == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지도', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '위치 정보가 없습니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    final point = LatLng(lat, lng);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('지도', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'my_ebook',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.location_pin,
                        size: 36,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenKakao,
              icon: const Icon(Icons.map_outlined),
              label: const Text('카카오 지도'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenNaver,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('네이버 지도'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BusinessLinksSection extends StatelessWidget {
  const _BusinessLinksSection({
    required this.business,
    required this.onOpenLink,
  });

  final Business business;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final links = <_LinkItem>[
      _LinkItem(label: '인스타그램', url: business.instagramUrl, icon: Icons.tag),
      _LinkItem(label: '블로그', url: business.blogUrl, icon: Icons.article),
      _LinkItem(
        label: '카카오 채널',
        url: business.kakaoChannelUrl,
        icon: Icons.chat_bubble_outline,
      ),
      _LinkItem(label: '웹사이트', url: business.websiteUrl, icon: Icons.public),
    ].where((item) => (item.url ?? '').trim().isNotEmpty).toList();
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('연결 링크', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: links
              .map(
                (item) => OutlinedButton.icon(
                  onPressed: () => onOpenLink(item.url ?? ''),
                  icon: Icon(item.icon, size: 18),
                  label: Text(item.label),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LinkItem {
  const _LinkItem({required this.label, required this.url, required this.icon});

  final String label;
  final String? url;
  final IconData icon;
}

class _BusinessCouponSection extends StatelessWidget {
  const _BusinessCouponSection({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final url = business.couponImageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('쿠폰', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BusinessNewsSection extends StatelessWidget {
  const _BusinessNewsSection({required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('소식', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(doc.data()['title'] as String? ?? '소식'),
                  subtitle: Text(
                    doc.data()['body'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
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
