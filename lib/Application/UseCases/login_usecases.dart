import 'package:dating_app/Data/Repositories/Abstract/login_repositories.dart';
import 'package:dating_app/Domain/Enteties/user_entities.dart';

class LoginUsecases {
  final LoginRepositories repository;

  LoginUsecases(this.repository);

  Future<Map<String, dynamic>> execute(UserLoginEntities entity) async {
    try {
      final result = await repository.loginUser(entity);
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
