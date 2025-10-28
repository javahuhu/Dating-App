
import 'package:dating_app/Domain/Enteties/user_entities.dart';

abstract class LoginRepositories {
  Future<Map<String,dynamic>> loginUser(UserLoginEntities user);
}