class UserModel {
  final String id;
  final String phoneNumber;
  final String name;
  final String token;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.token,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? json['phoneNumber']?.toString() ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        name: json['fullName'] ?? json['name'] ?? '',
        token: json['token'] ?? '',
        roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'fullName': name,
        'token': token,
        'roles': roles,
      };
}
