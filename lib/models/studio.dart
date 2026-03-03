class Studio {
  final String id;
  final String name;
  final String type; 
  final String description;
  final double pricePerHour;
  final double pricePerDay;
  final List<String> imageUrls;
  final double rating;
  final int reviewsCount;
  final String location;
  final String address;
  final double areaSquareMeters;
  final bool hasEngineer; 
  final bool hasInstruments; 
  final bool hasSoundproofing; 
  final bool hasAirConditioning; 
  final String equipment; 
  final List<String> amenities;
  final bool isAvailable;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;

  Studio({
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
    required this.areaSquareMeters,
    this.hasEngineer = false,
    this.hasInstruments = false,
    this.hasSoundproofing = true,
    this.hasAirConditioning = false,
    this.equipment = '',
    this.amenities = const [],
    this.isAvailable = true,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
  });

  bool get hourlyAvailable => pricePerHour > 0;

  static const _base = 'https://rentmuss-production.up.railway.app';
  static String _absUrl(String url) =>
      (url.isEmpty || url.startsWith('http')) ? url : '$_base$url';

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls']).map(_absUrl).toList()
          : [],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: (json['reviewsCount'] ?? 0).toInt(),
      location: json['location']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      areaSquareMeters: (json['areaSquareMeters'] ?? 0).toDouble(),
      hasEngineer: json['hasEngineer'] ?? false,
      hasInstruments: json['hasInstruments'] ?? false,
      hasSoundproofing: json['hasSoundproofing'] ?? true,
      hasAirConditioning: json['hasAirConditioning'] ?? false,
      equipment: json['equipment']?.toString() ?? '',
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : [],
      isAvailable: json['isAvailable'] ?? true,
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
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
      'areaSquareMeters': areaSquareMeters,
      'hasEngineer': hasEngineer,
      'hasInstruments': hasInstruments,
      'hasSoundproofing': hasSoundproofing,
      'hasAirConditioning': hasAirConditioning,
      'equipment': equipment,
      'amenities': amenities,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
