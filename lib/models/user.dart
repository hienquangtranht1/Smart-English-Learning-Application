class User {
  final String username;
  final bool isAdmin;
  final String email;

  User({required this.username, this.isAdmin = false, this.email = ''});

  Map<String, dynamic> toJson() => {
    'username': username,
    'isAdmin': isAdmin,
    'email': email,
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    username: j['username'] as String,
    isAdmin: j['isAdmin'] as bool? ?? false,
    email: (j['email'] as String?) ?? '',
  );
}
