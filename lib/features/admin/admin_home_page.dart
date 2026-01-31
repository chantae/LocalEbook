import 'package:flutter/material.dart';
import 'package:my_ebook/features/admin/admin_settings_page.dart';
import 'package:my_ebook/features/banners/admin_banners_page.dart';
import 'package:my_ebook/features/business_pages/admin_business_pages_page.dart';
import 'package:my_ebook/features/businesses/admin_businesses_page.dart';
import 'package:my_ebook/features/categories/admin_categories_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _AdminMenuItem(
        title: '배너 관리',
        icon: Icons.view_carousel_outlined,
        builder: (_) => const AdminBannersPage(),
      ),
      _AdminMenuItem(
        title: '카테고리 관리',
        icon: Icons.grid_view_rounded,
        builder: (_) => const AdminCategoriesPage(),
      ),
      _AdminMenuItem(
        title: '업체 관리',
        icon: Icons.storefront_outlined,
        builder: (_) => const AdminBusinessesPage(),
      ),
      _AdminMenuItem(
        title: '업체 페이지 관리',
        icon: Icons.collections_outlined,
        builder: (_) => const AdminBusinessPagesPage(),
      ),
      _AdminMenuItem(
        title: '관리자 설정',
        icon: Icons.settings_outlined,
        builder: (_) => const AdminSettingsPage(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 화면'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = cards[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(item.icon,
                    color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: item.builder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}
