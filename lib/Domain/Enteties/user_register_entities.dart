class UserRegisterEntities {
  final String username;
  final String email;
  final String password;
  final String confirmpassword;

  UserRegisterEntities({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmpassword,
  });

  UserRegisterEntities copWith({
    final String? username,
    final String? email,
    final String? password,
    final String? confirmpassword,
  }) {
    return UserRegisterEntities(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmpassword: confirmpassword ?? this.confirmpassword,
    );
  }
}
