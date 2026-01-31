import 'package:flutter/material.dart';
import 'package:my_ebook/models/banner_item.dart';
import 'package:my_ebook/widgets/banner/banner_card.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key, required this.banners});

  final List<BannerItem> banners;

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: banners.length,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          itemBuilder: (context, index) => BannerCard(banner: banners[index]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final active = index == _pageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(active ? 0.95 : 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
