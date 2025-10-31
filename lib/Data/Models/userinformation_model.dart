// lib/Data/Models/userinformation_model.dart
import 'dart:convert';
import 'package:dating_app/Domain/Enteties/userinformation_entities.dart';

class UserinformationModel extends UserinformationEntities {
  final String? profilePictureUrl;

  // Lists for structured fields
  final List<Map<String, dynamic>>? personalityList; // items with {left, right, value}
  final List<Map<String, dynamic>>? motivationsList; // items with {label, value}
  final List<String>? frustrationsList;
 

  UserinformationModel({
    required super.name,
    required super.age,
    required super.bio,
    super.profilePicture,
    super.personality,
    super.motivation,
    super.frustration,
    this.profilePictureUrl,
    super.gender,
    this.personalityList,
    this.motivationsList,
    this.frustrationsList,
    super.tags
  });

  /// Serialize only non-null fields (useful for partial updates)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name, 'age': age, 'bio': bio};

    if (profilePicture != null) map['profilePicture'] = profilePicture;
     if (gender != null) map['gender'] = gender;

    
    if (personality != null) map['personality'] = personality;
    if (motivation != null) map['motivation'] = motivation;
    if (frustration != null) map['frustration'] = frustration;

    // Prefer structured lists if present
    if (personalityList != null) map['personalityList'] = personalityList;
    if (motivationsList != null) map['motivationsList'] = motivationsList;
    if (frustrationsList != null) map['frustrationsList'] = frustrationsList;
    if (tags != null) map['tags'] = tags;

    return map;
  }

  /// Safe parser: accepts either List or JSON-encoded String
  static List<T>? _parseListField<T>(dynamic raw, T Function(dynamic) mapper) {
    try {
      if (raw == null) return null;
      if (raw is List) {
        return raw.map((e) => mapper(e)).whereType<T>().toList();
      }
      if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => mapper(e)).whereType<T>().toList();
        }
      }
    } catch (_) {
      // ignore parse errors and return null
    }
    return null;
  }

  factory UserinformationModel.fromMap(Map<String, dynamic> map) {
    final pic =
        (map['profilePicture'] as String?) ?? (map['profilePictureUrl'] as String?) ?? '';

    // personality items: expect list of {left,right,value}
    final personalityParsed = _parseListField<Map<String, dynamic>>(
      map['personalityList'] ?? map['personality'],
      (e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        // if item is a JSON string item, try decode
        if (e is String && e.trim().isNotEmpty) {
          try {
            final d = jsonDecode(e);
            if (d is Map) return Map<String, dynamic>.from(d);
          } catch (_) {}
        }
        return <String, dynamic>{};
      },
    );

    // motivations: expect list of {label,value}
    final motivationsParsed = _parseListField<Map<String, dynamic>>(
      map['motivationsList'] ?? map['motivation'] ?? map['motivations'],
      (e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        if (e is String && e.trim().isNotEmpty) {
          try {
            final d = jsonDecode(e);
            if (d is Map) return Map<String, dynamic>.from(d);
          } catch (_) {}
        }
        return <String, dynamic>{};
      },
    );

    // frustrations as list of strings
    final frustrationsParsed = _parseListField<String>(
      map['frustrationsList'] ?? map['frustration'] ?? map['frustrations'],
      (e) => e?.toString() ?? '',
    );

    // tags as list of strings
    final tagsParsed = _parseListField<String>(
      map['tags'] ?? map['tagList'],
      (e) => e?.toString() ?? '',
    );

    return UserinformationModel(
      name: (map['name'] as String?)?.trim() ?? '',
      age: (map['age'] is int) ? map['age'] as int : int.tryParse('${map['age']}') ?? 0,
      bio: (map['bio'] as String?)?.trim() ?? '',
      profilePicture: pic.isNotEmpty ? pic : null,
      profilePictureUrl: pic.isNotEmpty ? pic : null,
      personality: (map['personality'] as String?)?.trim(),
      motivation: (map['motivation'] as String?)?.trim(),
      frustration: (map['frustration'] as String?)?.trim(),
      gender: (map['gender'] as String?)?.trim(),
      personalityList: personalityParsed,
      motivationsList: motivationsParsed,
      frustrationsList: frustrationsParsed,
      tags: tagsParsed,
    );
  }

  
  UserinformationEntities toEntity() => UserinformationEntities(
        name: name,
        age: age,
        bio: bio,
        profilePicture: profilePicture,
        gender: gender,
        personality: personality,
        motivation: motivation,
        frustration: frustration,
        tags: tags,
      );
}
