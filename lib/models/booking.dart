class Booking {
  final String id;
  final String userId;
  final String itemId;
  final String itemType;
  final String sellerId;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerUnit;
  final int duration;
  final String durationType;
  final double totalPrice;
  final String status;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
    required this.pricePerUnit,
    required this.duration,
    required this.durationType,
    required this.totalPrice,
    this.status = 'pending',
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      itemId: json['itemId'] ?? '',
      itemType: json['itemType'] ?? '',
      sellerId: json['sellerId'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      pricePerUnit: (json['pricePerUnit'] ?? 0).toDouble(),
      duration: json['duration'] ?? 1,
      durationType: json['durationType'] ?? 'hour',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemId': itemId,
      'itemType': itemType,
      'sellerId': sellerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pricePerUnit': pricePerUnit,
      'duration': duration,
      'durationType': durationType,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isActive => isConfirmed && endDate.isAfter(DateTime.now());
  bool get isPast => endDate.isBefore(DateTime.now());

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Күтуде';
      case 'confirmed':
        return 'Расталған';
      case 'completed':
        return 'Аяқталған';
      case 'cancelled':
        return 'Болдырылмаған';
      default:
        return status;
    }
  }

  String get itemTypeText {
    switch (itemType) {
      case 'instrument':
        return 'Аспап';
      case 'stage':
        return 'Сахна';
      case 'studio':
        return 'Студия';
      default:
        return itemType;
    }
  }
}
