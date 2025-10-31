import 'package:dating_app/Data/Repositories/Abstract/discovery_repository.dart';

class SkipUser {
  final DiscoveryRepository repo;
  SkipUser(this.repo);
  Future<void> call({required String viewerId, required String skipId}) => repo.skip(viewerId: viewerId, skipId: skipId);
}
