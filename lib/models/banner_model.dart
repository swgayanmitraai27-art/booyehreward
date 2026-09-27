class BannerModel {
  String id;
  String title;
  String imageUrl;
  String clickUrl;
  bool isActive;
  DateTime createdAt;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.clickUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'clickUrl': clickUrl,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    clickUrl: json['clickUrl'] ?? '',
    isActive: json['isActive'] ?? true,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}
