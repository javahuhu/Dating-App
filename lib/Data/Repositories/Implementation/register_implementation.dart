import 'package:dating_app/Data/API/register_api.dart';
import 'package:dating_app/Data/Models/user_register_model.dart';
import 'package:dating_app/Data/Repositories/Abstract/register_repositories.dart';
import 'package:dating_app/Domain/Enteties/user_register_entities.dart';


class RegisterImplementation extends RegisterRepositories {
  RegisterAuth apireg;

  RegisterImplementation(this.apireg);

  @override
  Future<Map<String,dynamic>> registerUser(UserRegisterEntities register) async {
    final model = UserRegisterModel(
      username: register.username,
      email: register.email,
      password: register.password,
      confirmpassword: register.confirmpassword,
    );

    return await apireg.registerUser(model);
  }
}
