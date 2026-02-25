class User {

  User({
    required this.id,
    required this.email,
    this.name,
    this.userType,
    this.dniStatus,
    this.isActive,
    this.phone,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      name: json['full_name'], // Backend sends full_name
      userType: json['user_type'],
      dniStatus: json['dni_status'],
      isActive: json['is_active'],
      phone: json['phone'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
  final String id;
  final String email;
  final String? name;
  final String? userType;
  final String? dniStatus;
  final bool? isActive;
  final String? phone;
  final DateTime? createdAt;
}
