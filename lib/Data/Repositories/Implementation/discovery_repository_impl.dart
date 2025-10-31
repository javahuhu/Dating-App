

import 'package:dating_app/Data/Source/discovery_remote_datasource.dart';
import 'package:dating_app/Data/Repositories/Abstract/discovery_repository.dart';
import 'package:dating_app/Domain/Enteties/profile_entities.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remote;

  DiscoveryRepositoryImpl(this.remote);

  @override
  Future<List<ProfileEntities>> fetchProfiles({
    required String viewerId,
    int page = 0,
    int limit = 20,
    int? minAge,
    int? maxAge,
    double? lat,
    double? lon,
    double? maxDistanceKm,
  }) async {
    if (lat == null || lon == null) {
      throw ArgumentError('lat and lon required to fetch profiles');
    }

    final models = await remote.fetchProfiles(
      lat: lat,
      lon: lon,
      page: page,
      limit: limit,
      minAge: minAge,
      maxAge: maxAge,
      maxDistanceKm: maxDistanceKm,
    );

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> like({required String likerId, required String likedId}) async {
    final res = await remote.like(likedId);
    return res['matched'] == true;
  }

  @override
  Future<void> skip({required String viewerId, required String skipId}) async {
    await remote.skip(skipId);
  }
}
