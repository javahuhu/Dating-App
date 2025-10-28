
import 'package:dating_app/Domain/Enteties/user_register_entities.dart';

abstract class RegisterRepositories  {
  Future<Map<String, dynamic>> registerUser(UserRegisterEntities register);
}