import 'dart:async';
import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_util.dart';
import 'youtube_banner_player.dart';

class DynamicBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const DynamicBannerCarousel({super.key, required this.banners});

  @override
  State<DynamicBannerCarousel> createState() => _DynamicBannerCarouselState();
}

class _DynamicBannerCarouselState extends State<DynamicBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  String? _playingVideoBannerId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.banners.length > 1 && _playingVideoBannerId == null) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients && _playingVideoBannerId == null) {
          final nextPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DynamicBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                if (_playingVideoBannerId != null) {
                  _playingVideoBannerId = null;
                  _startAutoSlide();
                }
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final isCurrentlyPlaying = _playingVideoBannerId == banner.id;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isCurrentlyPlaying
                        ? YoutubeBannerPlayer(
                            banner: banner,
                            onClose: () {
                              setState(() => _playingVideoBannerId = null);
                              _startAutoSlide();
                            },
                          )
                        : _buildBannerCard(banner),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots
        if (widget.banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryAmber : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildBannerCard(BannerModel banner) {
    final isVideo = banner.isVideoBanner;
    final displayImg = (banner.imageUrl.isNotEmpty && !banner.imageUrl.contains('youtube.com'))
        ? banner.imageUrl
        : (isVideo ? banner.youtubeThumbnailUrl : banner.imageUrl);

    return InkWell(
      onTap: () {
        if (isVideo) {
          setState(() {
            _playingVideoBannerId = banner.id;
            _autoSlideTimer?.cancel();
          });
        } else if (banner.clickUrl.isNotEmpty) {
          UrlLauncherUtil.openUrl(banner.clickUrl);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Banner Image (Network or Asset)
          displayImg.startsWith('http')
              ? Image.network(
                  displayImg,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackBanner(banner),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryAmber, strokeWidth: 2),
                      ),
                    );
                  },
                )
              : Image.asset(
                  displayImg,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _buildFallbackBanner(banner),
                ),

          // Subtle Gradient Shadow Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(isVideo ? 90 : 30),
                  Colors.black.withAlpha(210),
                ],
              ),
            ),
          ),

          // Top Badges
          if (isVideo)
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withAlpha(120), blurRadius: 8),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'USER GUIDE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Center Glowing Play Button for Video Banners
          if (isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(220),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(150),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'TAP TO PLAY VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Banner Bottom Content
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (banner.title.isNotEmpty)
                        Text(
                          banner.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isVideo ? Icons.play_circle_fill : Icons.touch_app,
                            size: 12,
                            color: isVideo ? Colors.red.shade400 : AppTheme.primaryAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVideo ? 'Watch In-App Guide' : 'Tap to Open',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isVideo ? Colors.red.shade300 : AppTheme.primaryAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVideo ? Colors.red : AppTheme.primaryAmber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isVideo ? Icons.play_arrow_rounded : Icons.arrow_forward,
                    size: 14,
                    color: isVideo ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(BannerModel banner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              banner.isVideoBanner ? Icons.play_circle_outline : Icons.sports_esports,
              size: 36,
              color: banner.isVideoBanner ? Colors.red : AppTheme.primaryAmber,
            ),
            const SizedBox(height: 4),
            Text(
              banner.title.isNotEmpty ? banner.title : 'BOOYAH REWARDS ESPORTS',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
