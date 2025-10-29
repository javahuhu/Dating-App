import 'package:dating_app/Domain/Enteties/userinformation_entities.dart';

class UserinformationModel extends UserinformationEntities {
  final String? profilePictureUrl;

  UserinformationModel({
    required super.name,
    required super.age,
    required super.bio,
    super.profilePicture,
    this.profilePictureUrl,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'age': age, 'bio': bio};
  }

  factory UserinformationModel.fromMap(Map<String, dynamic> map) {
    final pic = map['profilePicture'] as String? ?? '';
    return UserinformationModel(
      name: map['name'] as String? ?? '',
      age: (map['age'] is int)
          ? map['age'] as int
          : int.tryParse('${map['age']}') ?? 0,
      bio: map['bio'] as String? ?? '',
      profilePicture: pic.isNotEmpty ? pic : null,
      profilePictureUrl: pic.isNotEmpty ? pic : null,
    );
  }

  /// Convert to Entity if needed
  UserinformationEntities toEntity() => UserinformationEntities(
    name: name,
    age: age,
    bio: bio,
    profilePicture: profilePicture,
  );
}
