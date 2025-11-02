class Stage {
  final String id;
  final String name;
  final String type; // concert, theater, club, outdoor, small, medium, large
  final String description;
  final double pricePerHour;
  final double pricePerDay;
  final List<String> imageUrls;
  final double rating;
  final int reviewsCount;
  final String location;
  final String address;
  final int capacity; // вместимость зрителей
  final double areaSquareMeters; // площадь сцены
  final bool hasSound; // звуковое оборудование
  final bool hasLighting; // световое оборудование
  final bool hasBackstage; // гримерные
  final bool hasParking; // парковка
  final List<String> amenities;
  final bool isAvailable;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;

  Stage({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.imageUrls,
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.location,
    required this.address,
    required this.capacity,
    required this.areaSquareMeters,
    this.hasSound = false,
    this.hasLighting = false,
    this.hasBackstage = false,
    this.hasParking = false,
    this.amenities = const [],
    this.isAvailable = true,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
  });

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      capacity: json['capacity'] ?? 0,
      areaSquareMeters: (json['areaSquareMeters'] ?? 0).toDouble(),
      hasSound: json['hasSound'] ?? false,
      hasLighting: json['hasLighting'] ?? false,
      hasBackstage: json['hasBackstage'] ?? false,
      hasParking: json['hasParking'] ?? false,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : [],
      isAvailable: json['isAvailable'] ?? true,
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'location': location,
      'address': address,
      'capacity': capacity,
      'areaSquareMeters': areaSquareMeters,
      'hasSound': hasSound,
      'hasLighting': hasLighting,
      'hasBackstage': hasBackstage,
      'hasParking': hasParking,
      'amenities': amenities,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
