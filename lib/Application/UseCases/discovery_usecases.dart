

import 'package:dating_app/Data/Repositories/Abstract/discovery_repository.dart';
import 'package:dating_app/Domain/Enteties/profile_entities.dart';

class FetchProfiles {
  final DiscoveryRepository repo;
  FetchProfiles(this.repo);
  Future<List<ProfileEntities>> call({required String viewerId, required double lat, required double lon, int page = 0, int limit = 20, int? minAge, int? maxAge, double? maxDistanceKm}) {
    return repo.fetchProfiles(viewerId: viewerId, page: page, limit: limit, minAge: minAge, maxAge: maxAge, lat: lat, lon: lon, maxDistanceKm: maxDistanceKm);
  }
}
