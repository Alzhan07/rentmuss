class Review {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String itemId;
  final String itemType;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar = '',
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username'] ?? 'Қолданушы',
      userAvatar: json['userAvatar'] ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemType: json['itemType'] ?? '',
      rating: (json['rating'] ?? 1).toInt(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length > 1 ? 2 : 1).toUpperCase();
  }
}
