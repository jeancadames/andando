class ReviewCommentModel {
  final int id;
  final int reviewId;
  final String comment;
  final String userName;
  final String? userPhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isOwner;

  const ReviewCommentModel({
    required this.id,
    required this.reviewId,
    required this.comment,
    required this.userName,
    required this.userPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isEdited,
    required this.isOwner,
  });

  factory ReviewCommentModel.fromJson(Map<String, dynamic> json) {
    return ReviewCommentModel(
      id: _toInt(json['id']),
      reviewId: _toInt(json['review_id']),
      comment: json['comment']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Usuario',
      userPhotoUrl: json['user_photo_url']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      isEdited: _toBool(json['is_edited']),
      isOwner: _toBool(json['is_owner']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}