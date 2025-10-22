class Seller {
  String? id;
  String? name;
  String? email;
  String? phone;

  Seller({this.id, this.name, this.email, this.phone});

  // Factory method to create a Seller from JSON
  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  // Method to convert a Seller to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}



лпткпкпрркшрп