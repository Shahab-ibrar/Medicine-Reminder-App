class UserProfile {
  final String uid;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
