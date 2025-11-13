class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? bio;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.bio,
  });

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      bio: json['bio'],
    );
  }

  // Convert User ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
    };
  }

  // Copy with untuk update data
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
    );
  }
}
