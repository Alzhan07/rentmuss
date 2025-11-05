enum UserRole { user, seller, admin }

enum SellerApplicationStatus { none, pending, approved, rejected }

class SellerInfo {
  final String? shopName;
  final String? shopDescription;
  final String? shopLogo;
  final bool verified;
  final double rating;
  final int totalSales;

  SellerInfo({
    this.shopName,
    this.shopDescription,
    this.shopLogo,
    this.verified = false,
    this.rating = 0.0,
    this.totalSales = 0,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      shopName: json['shopName'],
      shopDescription: json['shopDescription'],
      shopLogo: json['shopLogo'],
      verified: json['verified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalSales: json['totalSales'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'shopDescription': shopDescription,
      'shopLogo': shopLogo,
      'verified': verified,
      'rating': rating,
      'totalSales': totalSales,
    };
  }
}

class SellerApplication {
  final SellerApplicationStatus status;
  final DateTime? appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  SellerApplication({
    this.status = SellerApplicationStatus.none,
    this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory SellerApplication.fromJson(Map<String, dynamic> json) {
    return SellerApplication(
      status: _parseStatus(json['status']),
      appliedAt:
          json['appliedAt'] != null ? DateTime.parse(json['appliedAt']) : null,
      reviewedAt:
          json['reviewedAt'] != null
              ? DateTime.parse(json['reviewedAt'])
              : null,
      reviewedBy: json['reviewedBy'],
      rejectionReason: json['rejectionReason'],
    );
  }

  static SellerApplicationStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return SellerApplicationStatus.pending;
      case 'approved':
        return SellerApplicationStatus.approved;
      case 'rejected':
        return SellerApplicationStatus.rejected;
      default:
        return SellerApplicationStatus.none;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'appliedAt': appliedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }
}

class User {
  final String id;
  final String username;
  final String? email;
  final UserRole role;
  final String? avatar;
  final SellerInfo? sellerInfo;
  final SellerApplication? sellerApplication;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.role = UserRole.user,
    this.avatar,
    this.sellerInfo,
    this.sellerApplication,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      role: _parseRole(json['role']),
      avatar: json['avatar'],
      sellerInfo:
          json['sellerInfo'] != null
              ? SellerInfo.fromJson(json['sellerInfo'])
              : null,
      sellerApplication:
          json['sellerApplication'] != null
              ? SellerApplication.fromJson(json['sellerApplication'])
              : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.name,
      'avatar': avatar,
      'sellerInfo': sellerInfo?.toJson(),
      'sellerApplication': sellerApplication?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? username,
    String? email,
    UserRole? role,
    String? avatar,
    SellerInfo? sellerInfo,
    SellerApplication? sellerApplication,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      sellerInfo: sellerInfo ?? this.sellerInfo,
      sellerApplication: sellerApplication ?? this.sellerApplication,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get fullName => '$username';
  bool get isSeller => role == UserRole.seller;
  bool get isAdmin => role == UserRole.admin;
  bool get canApplyForSeller =>
      role == UserRole.user &&
      (sellerApplication?.status == SellerApplicationStatus.none ||
          sellerApplication?.status == SellerApplicationStatus.rejected);
}
