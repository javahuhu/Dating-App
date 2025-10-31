import 'package:dating_app/Data/API/discovery_api.dart';
import 'package:dating_app/Data/Source/discovery_remote_datasource.dart';
import 'package:dating_app/Data/Repositories/Abstract/discovery_repository.dart';
import 'package:dating_app/Data/Repositories/Implementation/discovery_repository_impl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';



final discoveryApiProvider = Provider<DiscoveryApi>((ref) {
  return DiscoveryApi(baseUrl: 'http://localhost:3000'); 
});

final discoveryRemoteProvider = Provider<DiscoveryRemoteDataSource>((ref) {
  final api = ref.read(discoveryApiProvider);
  return DiscoveryRemoteDataSource(api);
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final remote = ref.read(discoveryRemoteProvider);
  return DiscoveryRepositoryImpl(remote);
});
