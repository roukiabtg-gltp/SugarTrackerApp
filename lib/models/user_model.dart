class UserModel {
  final String uid;
  final String email;
  final String role; // يمكن أن يكون 'doctor' أو 'secretary'

  UserModel({required this.uid, required this.email, required this.role});

  factory UserModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'doctor',
    );
  }
}