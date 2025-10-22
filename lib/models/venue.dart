class Venue {
  final String id;
  final String username;
  final String type; // 'stage', 'instrument', 'studio'
  final String description;
  final double pricePerHour;
  final String imageUrl;
  final double rating;
  final String location;
  final List<String> amenities;
  final bool isAvailable;

  Venue({
    required this.id,
    required this.username,
    required this.type,
    required this.description,
    required this.pricePerHour,
    required this.imageUrl,
    this.rating = 0.0,
    required this.location,
    this.amenities = const [],
    this.isAvailable = true,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : [],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'type': type,
      'description': description,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'rating': rating,
      'location': location,
      'amenities': amenities,
      'isAvailable': isAvailable,
    };
  }
}
