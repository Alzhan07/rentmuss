class Instrument {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String model;
  final String description;
  final double pricePerHour;
  final double pricePerDay;
  final List<String> imageUrls;
  final double rating;
  final int reviewsCount;
  final String location;
  final String condition;
  final bool isAvailable;
  final List<String> features;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;

  Instrument({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.model,
    required this.description,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.imageUrls,
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.location,
    this.condition = 'good',
    this.isAvailable = true,
    this.features = const [],
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
  });

  bool get hourlyAvailable => pricePerHour > 0;

  static const _base = 'https://rentmuss-production.up.railway.app';
  static String _absUrl(String url) =>
      (url.isEmpty || url.startsWith('http')) ? url : '$_base$url';

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls']).map(_absUrl).toList()
          : [],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      location: json['location'] ?? '',
      condition: json['condition'] ?? 'good',
      isAvailable: json['isAvailable'] ?? true,
      features:
          json['features'] != null ? List<String>.from(json['features']) : [],
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'description': description,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'location': location,
      'condition': condition,
      'isAvailable': isAvailable,
      'features': features,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
