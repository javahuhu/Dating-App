import 'package:dating_app/Domain/Enteties/user_register_entities.dart';

class UserRegisterModel extends UserRegisterEntities {
  UserRegisterModel({
    required super.username,
    required super.email,
    required super.password,
    required super.confirmpassword,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": username,
      "email": email,
      "password": password,
      
    };
  }
}
