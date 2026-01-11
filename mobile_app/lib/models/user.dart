class User {
  final String id;
  final String email;
  final String name;
  final String? userName; // Web uyumluluğu için
  final String? avatar;
  final String? profilePhotoUrl; // Web uyumluluğu için
  final DateTime createdAt;
  final DateTime? memberSince; // Web uyumluluğu için

  User({
    required this.id,
    required this.email,
    required this.name,
    this.userName,
    this.avatar,
    this.profilePhotoUrl,
    required this.createdAt,
    this.memberSince,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? json['userName'] as String? ?? json['email'] as String,
      userName: json['userName'] as String?,
      avatar: json['avatar'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : (json['memberSince'] != null 
              ? DateTime.parse(json['memberSince'] as String)
              : DateTime.now()),
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userName': userName ?? name,
      'avatar': avatar ?? profilePhotoUrl,
      'profilePhotoUrl': profilePhotoUrl ?? avatar,
      'createdAt': createdAt.toIso8601String(),
      'memberSince': (memberSince ?? createdAt).toIso8601String(),
    };
  }
  
  // Helper getter for profile photo
  String? get photoUrl => profilePhotoUrl ?? avatar;
}
