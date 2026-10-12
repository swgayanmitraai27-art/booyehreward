class BannerModel {
  String id;
  String title;
  String imageUrl;
  String clickUrl;
  String? videoUrl; // YouTube or video URL for playing in banner
  bool isActive;
  DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.clickUrl,
    this.videoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  /// Extracts YouTube Video ID from any format (shorts, youtu.be, watch?v=, embed, etc.)
  static String? extractYouTubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    // 1. youtu.be/<id> or embed/<id> or shorts/<id>
    final RegExp regExp1 = RegExp(r'(?:youtu\.be\/|v\/|u\/\w\/|embed\/|shorts\/)([\w-]{11})', caseSensitive: false);
    final match1 = regExp1.firstMatch(trimmed);
    if (match1 != null && match1.groupCount >= 1) {
      return match1.group(1);
    }

    // 2. youtube.com/watch?v=<id>
    final RegExp regExp2 = RegExp(r'(?:[?&]v=)([\w-]{11})', caseSensitive: false);
    final match2 = regExp2.firstMatch(trimmed);
    if (match2 != null && match2.groupCount >= 1) {
      return match2.group(1);
    }

    // 3. Raw 11-char ID
    if (RegExp(r'^[\w-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  /// Returns the YouTube Video ID if available in videoUrl, clickUrl, or imageUrl
  String? get youtubeVideoId {
    final direct = extractYouTubeId(videoUrl);
    if (direct != null) return direct;
    final fromClick = extractYouTubeId(clickUrl);
    if (fromClick != null) return fromClick;
    final fromImage = extractYouTubeId(imageUrl);
    if (fromImage != null) return fromImage;
    return null;
  }

  bool get isVideoBanner => youtubeVideoId != null;

  String get youtubeThumbnailUrl {
    final id = youtubeVideoId;
    if (id != null) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return imageUrl;
  }

  String get youtubeEmbedUrl {
    final id = youtubeVideoId;
    return 'https://www.youtube-nocookie.com/embed/$id?autoplay=1&rel=0&modestbranding=1&playsinline=1';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'clickUrl': clickUrl,
    'videoUrl': videoUrl,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    clickUrl: json['clickUrl'] ?? '',
    videoUrl: json['videoUrl'] ?? json['video_url'],
    isActive: json['isActive'] ?? true,
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt']) ?? DateTime.now())
        : DateTime.now(),
  );
}
