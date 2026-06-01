class ReviewPhotoModel {
  final int id;
  final String url;

  const ReviewPhotoModel({
    required this.id,
    required this.url,
  });

  factory ReviewPhotoModel.fromJson(Map<String, dynamic> json) {
    return ReviewPhotoModel(
      id: _toInt(json['id']),
      url: json['url']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}