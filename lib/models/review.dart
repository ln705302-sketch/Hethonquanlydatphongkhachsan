class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.score,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isHidden = false,
  });

  final String id;
  final String userId;
  final String userName;
  final double score; // 1-10
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt; // Lần sửa gần nhất của khách
  final bool isHidden; // Quản lý ẩn đánh giá không phù hợp

  Review copyWith({
    double? score,
    String? comment,
    DateTime? updatedAt,
    bool? isHidden,
  }) =>
      Review(
        id: id,
        userId: userId,
        userName: userName,
        score: score ?? this.score,
        comment: comment ?? this.comment,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isHidden: isHidden ?? this.isHidden,
      );

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        score: (json['score'] as num).toDouble(),
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.parse(json['updatedAt'] as String),
        isHidden: json['isHidden'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'score': score,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isHidden': isHidden,
      };
}
