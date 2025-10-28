import 'package:dating_app/Data/API/login_api.dart';
import 'package:dating_app/Data/Models/user_login_model.dart';
import 'package:dating_app/Data/Repositories/Abstract/login_repositories.dart';
import 'package:dating_app/Domain/Enteties/user_entities.dart';

class LoginImplementation extends LoginRepositories {
  LoginApi apiLog;

  LoginImplementation(this.apiLog);

  @override
  Future<Map<String, dynamic>> loginUser(UserLoginEntities user) async {
    final model = UserLoginModel(email: user.email, password: user.password);
    return await apiLog.loginUser(model);
  }
}
