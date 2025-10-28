class UserLoginEntities {
  final String email;
  final String password;

  UserLoginEntities({required this.email, required this.password});

  UserLoginEntities copWith({final String? email, final String? password}) {
    return UserLoginEntities(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
