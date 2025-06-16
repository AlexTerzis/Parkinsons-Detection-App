import 'package:cloud_firestore/cloud_firestore.dart';

import 'doctor_note.dart';
import 'test_result.dart';

enum ReportStatus { pending, reviewed, closed }

class PatientReport {
  const PatientReport({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.results,
    required this.sentAt,
    this.status = ReportStatus.pending,
    this.notes = const [],
  });

  final String id;
  final String patientId;
  final String doctorId;
  final List<TestResult> results;
  final DateTime sentAt;
  final ReportStatus status;
  final List<DoctorNote> notes;

  factory PatientReport.fromJson(Map<String, dynamic> json, String documentId) {
    return PatientReport(
      id: documentId,
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(json['status'] as String? ?? 'pending'),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => TestResult.fromJson(e as Map<String, dynamic>, ''))
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => DoctorNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status.name,
      'results': results.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
    };
  }

  static ReportStatus _statusFromString(String value) {
    switch (value) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'closed':
        return ReportStatus.closed;
      default:
        return ReportStatus.pending;
    }
  }
}
