import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/authentication_service.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? name;

  factory AppUser.fromJson(Map<String, dynamic> json, String documentId) {
    return AppUser(
      uid: documentId,
      email: json['email'] as String? ?? '',
      role: _roleFromString(json['role'] as String? ?? 'patient'),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'role': role.value,
      if (name != null) 'name': name,
    };
  }

  static UserRole _roleFromString(String value) {
    return value == 'doctor' ? UserRole.doctor : UserRole.patient;
  }

  DocumentReference<Map<String, dynamic>> get firestoreRef =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  AppUser copyWith({String? name}) {
    return AppUser(
      uid: uid,
      email: email,
      role: role,
      name: name ?? this.name,
    );
  }
}
