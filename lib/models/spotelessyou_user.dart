import 'package:cloud_firestore/cloud_firestore.dart';

class SpotelessYouUser {
  final String uid;
  final String email;
  final String password;
  final String userRole;
  final String name;
  final String age;
  final String district;
  final String mobile;
  final String bio;
  final String gender;

  SpotelessYouUser({
    required this.uid,
    required this.email,
    required this.password,
    required this.userRole,
    required this.name,
    required this.age,
    required this.district,
    required this.mobile,
    required this.bio,
    required this.gender,
  });

  // Factory constructor to create an instance from Firestore
  factory SpotelessYouUser.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return SpotelessYouUser(
      uid: snapshot.id,
      email: data?['email'] ?? '',
      password: data?['password'] ?? '',
      userRole: data?['userRole'] ?? '',
      name: data?['name'] ?? '',
      age: data?['age'] ?? '',
      district: data?['district'] ?? '',
      mobile: data?['mobile'] ?? '',
      bio: data?['bio'] ?? '',
      gender: data?['gender'] ?? '',
    );
  }

  // Converts an instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'userRole': userRole,
      'name': name,
      'age': age,
      'district': district,
      'mobile': mobile,
      'bio': bio,
      'gender': gender,
    };
  }

  // Converts an instance to a JSON representation
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Creates a copy of the user with modified fields
  SpotelessYouUser copyWith({
    String? uid,
    String? email,
    String? password,
    String? userRole,
    String? name,
    String? age,
    String? district,
    String? mobile,
    String? bio,
    String? gender,
  }) {
    return SpotelessYouUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      password: password ?? this.password,
      userRole: userRole ?? this.userRole,
      name: name ?? this.name,
      age: age ?? this.age,
      district: district ?? this.district,
      mobile: mobile ?? this.mobile,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
    );
  }
}
