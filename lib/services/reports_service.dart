import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/patient_report.dart';
import '../models/test_result.dart';
import '../models/doctor_note.dart';

class ReportsService {
  ReportsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reportsCol =>
      _firestore.collection('reports');

  Future<List<AppUser>> fetchAllDoctors() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _usersCol.where('role', isEqualTo: 'doctor').get();
    return snap.docs.map((d) => AppUser.fromJson(d.data(), d.id)).toList();
  }

  Future<AppUser?> fetchUserById(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromJson(doc.data()!, doc.id);
  }

  Future<void> sendResultsToDoctor({
    required String patientId,
    required String doctorId,
    required List<TestResult> results,
  }) async {
    final PatientReport report = PatientReport(
      id: '',
      patientId: patientId,
      doctorId: doctorId,
      results: results,
      sentAt: DateTime.now(),
    );

    await _reportsCol.add(report.toJson());
  }

  Stream<List<PatientReport>> watchReportsForPatient(String patientId) {
    return _reportsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PatientReport.fromJson(d.data(), d.id))
            .toList());
  }

  Stream<List<PatientReport>> watchReportsForDoctor(String doctorId) {
    return _reportsCol
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PatientReport.fromJson(d.data(), d.id))
            .toList());
  }

  Future<void> addNoteToReport({
    required String reportId,
    required DoctorNote note,
  }) async {
    await _reportsCol.doc(reportId).update({
      'notes': FieldValue.arrayUnion([note.toJson()]),
      'status': 'reviewed',
    });
  }
}
