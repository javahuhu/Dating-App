// lib/data/datasources/discovery_remote_datasource.dart
import 'package:dating_app/Data/API/discovery_api.dart';
import '../models/profile_model.dart';

class DiscoveryRemoteDataSource {
  final DiscoveryApi api;
  DiscoveryRemoteDataSource(this.api);

  Future<List<ProfileModel>> fetchProfiles({
    required double lat,
    required double lon,
    int page = 0,
    int limit = 20,
    int? minAge,
    int? maxAge,
    double? maxDistanceKm,
  }) async {
    final raw = await api.fetchProfiles(
      lat: lat,
      lon: lon,
      page: page,
      limit: limit,
      minAge: minAge,
      maxAge: maxAge,
      maxDistanceKm: maxDistanceKm,
    );
    return raw.map((m) => ProfileModel.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> like(String targetId) => api.like(targetId);

  Future<void> skip(String targetId) => api.skip(targetId);
}
