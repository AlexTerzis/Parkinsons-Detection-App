import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorNote {
  const DoctorNote({
    required this.doctorId,
    required this.note,
    required this.createdAt,
  });

  final String doctorId;
  final String note;
  final DateTime createdAt;

  factory DoctorNote.fromJson(Map<String, dynamic> json) {
    return DoctorNote(
      doctorId: json['doctorId'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'doctorId': doctorId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
