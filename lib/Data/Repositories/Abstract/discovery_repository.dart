
import 'package:dating_app/Domain/Enteties/profile_entities.dart';

abstract class DiscoveryRepository {
  Future<List<ProfileEntities>> fetchProfiles({
    required String viewerId,
    int page = 0,
    int limit = 20,
    int? minAge,
    int? maxAge,
    double? lat,
    double? lon,
    double? maxDistanceKm,
  });

  /// returns true if like caused a match
  Future<bool> like({required String likerId, required String likedId});

  Future<void> skip({required String viewerId, required String skipId});
}
