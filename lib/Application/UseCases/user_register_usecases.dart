import 'package:dating_app/Data/Repositories/Abstract/register_repositories.dart';
import 'package:dating_app/Domain/Enteties/user_register_entities.dart';

/// Use case for registering a user. It delegates to the repository,
/// and returns whatever the repository returns (usually a Map with success/message).
class RegisterUseCase {
  final RegisterRepositories repository;

  RegisterUseCase(this.repository);

  Future<Map<String, dynamic>> execute(UserRegisterEntities entity) async {
    try {
      final result = await repository.registerUser(entity);
      return result;
    } catch (e) {
      
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
