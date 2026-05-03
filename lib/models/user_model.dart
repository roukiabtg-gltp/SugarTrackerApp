class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String birthDate;
  final String gender;
  final String bloodType;
  final String? address;
  final String role;
  final String? profileImage; // أضفنا هذا الحقل

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.bloodType,
    this.address,
    required this.role,
    this.profileImage, // أضفنا هذا الحقلprofileImage: map['profile_image'], // جلب الرابط من Firebase
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      id: id,
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      birthDate: map['birth_date'] ?? '',
      gender: map['gender'] ?? '',
      bloodType: map['blood_type'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'patient',
      profileImage: map['profile_image'], // جلب الرابط من Firebase
    );
  }

  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      DateTime birth = DateTime.parse(birthDate);
      DateTime today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) age--;
      return age;
    } catch (e) {
      return 0;
    }
  }
}