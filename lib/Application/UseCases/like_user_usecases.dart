import 'package:dating_app/Data/Repositories/Abstract/discovery_repository.dart';

class LikeUser {
  final DiscoveryRepository repo;
  LikeUser(this.repo);
  Future<bool> call({required String likerId, required String likedId}) =>
      repo.like(likerId: likerId, likedId: likedId);
}
