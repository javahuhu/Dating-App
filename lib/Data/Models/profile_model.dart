// lib/data/models/profile_model.dart
import 'dart:convert';
import 'package:dating_app/Domain/Enteties/profile_entities.dart';


class ProfileModel {
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

  ProfileModel({
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

  factory ProfileModel.fromMap(Map<String, dynamic> m) {
    // parse tags defensively: could be JSON string or list
    List<String>? parsedTags;
    final rawTags = m['tags'];
    if (rawTags is String && rawTags.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTags);
        if (decoded is List) parsedTags = decoded.map((e) => e.toString()).toList();
      } catch (_) {
        parsedTags = [rawTags];
      }
    } else if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    final distanceVal = m['distanceKm'] ?? m['distance'] ?? m['distance_km'];
    double? distanceParsed;
    if (distanceVal is num) distanceParsed = distanceVal.toDouble();

    return ProfileModel(
      id: (m['_id'] ?? m['id']).toString(),
      name: (m['name'] ?? '').toString(),
      age: (m['age'] is int) ? m['age'] : int.tryParse('${m['age']}') ?? 0,
      bio: (m['bio'] ?? '').toString(),
      profilePicture: m['profilePicture'] as String?,
      distanceKm: distanceParsed,
      personality: m['personality'] as String?,
      motivation: m['motivation'] as String?,
      frustration: m['frustration'] as String?,
      tags: parsedTags,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'bio': bio,
        'profilePicture': profilePicture,
        'distanceKm': distanceKm,
        'personality': personality,
        'motivation': motivation,
        'frustration': frustration,
        'tags': tags,
      };

  ProfileEntities toEntity() {
    return ProfileEntities(
      id: id,
      name: name,
      age: age,
      bio: bio,
      profilePicture: profilePicture,
      distanceKm: distanceKm,
      personality: personality,
      motivation: motivation,
      frustration: frustration,
      tags: tags,
    );
  }

  factory ProfileModel.fromEntity(ProfileEntities e) {
    return ProfileModel(
      id: e.id,
      name: e.name,
      age: e.age,
      bio: e.bio,
      profilePicture: e.profilePicture,
      distanceKm: e.distanceKm,
      personality: e.personality,
      motivation: e.motivation,
      frustration: e.frustration,
      tags: e.tags,
    );
  }
}
