import 'package:dating_app/Domain/Enteties/user_entities.dart';

class UserLoginModel extends UserLoginEntities {
  UserLoginModel({required super.email, required super.password});

  Map<String,dynamic> toJson() {
    return {
      "email": email,
      "password": password,
    };
  }
}
