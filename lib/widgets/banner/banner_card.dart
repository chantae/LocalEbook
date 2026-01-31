import 'package:flutter/material.dart';
import 'package:my_ebook/models/banner_item.dart';

class BannerCard extends StatelessWidget {
  const BannerCard({super.key, required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = banner.color ?? theme.colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty)
            Image.network(
              banner.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  background.withOpacity(0.85),
                  background.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
