class User {

  User({
    required this.id,
    required this.email,
    this.name,
    this.userType,
    this.dniStatus,
    this.isActive,
    this.phone,
    this.isPhoneVerified,
    this.createdAt,
    this.rejectionReason,
    this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      name: json['full_name'],
      userType: json['user_type'],
      dniStatus: json['dni_status'],
      isActive: json['is_active'],
      phone: json['phone'],
      isPhoneVerified: json['is_phone_verified'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      rejectionReason: json['rejection_reason'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  final String id;
  final String email;
  final String? name;
  final String? userType;
  final String? dniStatus;
  final bool? isActive;
  final String? phone;
  final bool? isPhoneVerified;
  final DateTime? createdAt;
  final String? rejectionReason;
  final String? profilePhotoUrl;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    String? dniStatus,
    bool? isActive,
    String? phone,
    bool? isPhoneVerified,
    DateTime? createdAt,
    String? rejectionReason,
    String? profilePhotoUrl,
    bool clearProfilePhoto = false,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      dniStatus: dniStatus ?? this.dniStatus,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      profilePhotoUrl: clearProfilePhoto ? null : (profilePhotoUrl ?? this.profilePhotoUrl),
    );
  }
}
