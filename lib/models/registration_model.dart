import 'dart:convert';

class RegistrationModel {
  final String username;
  final String password;
  final String? fullname;
  final DateTime? dob;
  final String? gender;
  final String? phone;
  final String email;
  final String? address;

  RegistrationModel({
    required this.username,
    required this.password,
    required this.email,
    this.fullname,
    this.dob,
    this.gender,
    this.phone,
    this.address,
  });

  RegistrationModel copyWith({
    String? username,
    String? password,
    String? fullname,
    DateTime? dob,
    String? gender,
    String? phone,
    String? email,
    String? address,
  }) {
    return RegistrationModel(
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'fullname': fullname,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullname: json['fullname'] != null ? json['fullname'].toString() : null,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      gender: json['gender'] != null ? json['gender'].toString() : null,
      phone: json['phone'] != null ? json['phone'].toString() : null,
      address: json['address'] != null ? json['address'].toString() : null,
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  bool get isValidForRequest {
    if (username.trim().isEmpty) return false;
    if (password.length < 6) return false;
    if (email.trim().isEmpty || !email.contains('@')) return false;
    return true;
  }
}
