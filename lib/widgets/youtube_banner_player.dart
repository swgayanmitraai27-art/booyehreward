import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import 'youtube/youtube_player_view.dart';

class YoutubeBannerPlayer extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onClose;
  final bool isFullScreen;

  const YoutubeBannerPlayer({
    super.key,
    required this.banner,
    this.onClose,
    this.isFullScreen = false,
  });

  static void showFullScreenDialog(BuildContext context, BannerModel banner) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    tooltip: 'Close Player',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 16:9 Video Player Box
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: buildPlatformYouTubePlayer(
                      videoId: banner.youtubeVideoId ?? '',
                      embedUrl: banner.youtubeEmbedUrl,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoId = banner.youtubeVideoId ?? '';
    if (videoId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Platform-specific Player (iframe on Web, WebView on Mobile)
          buildPlatformYouTubePlayer(
            videoId: videoId,
            embedUrl: banner.youtubeEmbedUrl,
          ),

          // Top Overlay Controls
          Positioned(
            top: 6,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Video Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(120), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.red, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PLAYING GUIDE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls: Fullscreen & Close
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fullscreen
                    InkWell(
                      onTap: () => showFullScreenDialog(context, banner),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Close / Stop
                    if (onClose != null)
                      InkWell(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
