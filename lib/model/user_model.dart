class User {
  final int nic;
  final String name;
  final String email;
  final String password;

  User({
    required this.nic,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'nic': nic,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      nic: map['nic'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
    );
  }
}


