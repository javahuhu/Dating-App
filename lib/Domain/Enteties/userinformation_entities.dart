

class UserinformationEntities {
  final String name;
  final int age;
  final String bio;
  final String? profilePicture;

  UserinformationEntities({
    required this.name,
    required this.age,
    required this.bio,
    required this.profilePicture,
  });

  UserinformationEntities copyWith({
    String? name,
    int? age,
    String? bio,
    String? profilePicture,
  }) {
    return UserinformationEntities(
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
