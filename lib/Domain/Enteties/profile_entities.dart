// lib/domain/entities/profile_entities.dart
class ProfileEntities {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String? profilePicture;
  final double? distanceKm;
  final String? personality;
  final String? motivation;
  final String? frustration;
  final List<String>? tags;

  const ProfileEntities({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    this.profilePicture,
    this.distanceKm,
    this.personality,
    this.motivation,
    this.frustration,
    this.tags,
  });

  bool get isAdult => age >= 18;

  ProfileEntities copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    String? profilePicture,
    double? distanceKm,
    String? personality,
    String? motivation,
    String? frustration,
    List<String>? tags,
  }) {
    return ProfileEntities(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      distanceKm: distanceKm ?? this.distanceKm,
      personality: personality ?? this.personality,
      motivation: motivation ?? this.motivation,
      frustration: frustration ?? this.frustration,
      tags: tags ?? this.tags,
    );
  }
}
