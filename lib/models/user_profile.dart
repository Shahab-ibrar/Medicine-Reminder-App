/// Represents a user's profile data stored in Firestore.
///
/// New field added (backward-compatible):
///   - [photoUrl]: nullable URL of the user's profile photo in Firebase Storage.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final int age;
  final DateTime createdAt;
  final String? photoUrl; // null if no photo has been set

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      photoUrl: json['photoUrl'] as String?, // null for existing records
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      if (photoUrl != null) 'photoUrl': photoUrl, // only write when set
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    int? age,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
