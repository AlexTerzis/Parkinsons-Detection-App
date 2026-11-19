import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/test_series_analysis.dart';
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
    this.patientName,
    this.status = ReportStatus.pending,
    this.notes = const [],
    this.summaries = const [],
  });

  final String id;
  final String patientId;
  final String doctorId;

  /// The patient's name, copied onto the report when it is sent.
  ///
  /// Carried here rather than looked up, because the doctor cannot read the
  /// patient's profile document — the security rules give each user access to
  /// their own only, which is right, and widening them to let doctors read
  /// patient profiles would expose far more than a name.
  ///
  /// The patient can obviously read their own name, so they write it at the
  /// moment of sending. `null` on reports written before this field existed;
  /// see [displayName].
  final String? patientName;
  /// The most recent attempts, not every one ever taken.
  ///
  /// Capped at [TestSeriesAnalysis.recentWindow] per test. This used to carry
  /// the patient's whole history, which grows without limit — and camera
  /// results carry nested per-hand task data, so a long-running account would
  /// eventually cross Firestore's 1 MiB document ceiling and sending would
  /// start failing outright.
  final List<TestResult> results;

  final DateTime sentAt;
  final ReportStatus status;
  final List<DoctorNote> notes;

  /// What every attempt adds up to, per test, over the patient's whole history.
  ///
  /// Computed at send time because [results] is truncated: the doctor cannot
  /// work out an all-time figure from the last ten readings. Empty on reports
  /// written before this existed — see [seriesSummaries], which covers that.
  final List<TestSeriesSummary> summaries;

  /// The per-test summaries to display, whatever vintage the report is.
  ///
  /// Reports written before summaries existed carry every result instead of the
  /// last ten, so summarising those results gives the same all-time answer the
  /// patient's device would have. Old reports therefore read *better* than they
  /// used to rather than losing anything.
  List<TestSeriesSummary> get seriesSummaries =>
      summaries.isNotEmpty ? summaries : TestSeriesAnalysis.summarise(results);

  factory PatientReport.fromJson(Map<String, dynamic> json, String documentId) {
    return PatientReport(
      id: documentId,
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      patientName: json['patientName'] as String?,
      sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(json['status'] as String? ?? 'pending'),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => TestResult.fromJson(e as Map<String, dynamic>, ''))
          .toList(),
      notes: (json['notes'] as List<dynamic>? ?? [])
          .map((e) => DoctorNote.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Absent on every report written before summaries existed. Left empty
      // rather than faked; [seriesSummaries] handles that case.
      summaries: (json['summaries'] as List<dynamic>? ?? [])
          .map((e) => TestSeriesSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      if (patientName != null) 'patientName': patientName,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status.name,
      'results': results.map((e) => e.toJson()).toList(),
      'notes': notes.map((e) => e.toJson()).toList(),
      'summaries': summaries.map((e) => e.toJson()).toList(),
    };
  }

  /// What to show a doctor for this patient.
  ///
  /// Falls back to the account id for reports sent before the name was carried
  /// on the report. Those cannot be resolved after the fact — the lookup that
  /// would have done it is exactly the one the rules deny — so an id is the
  /// honest answer rather than a blank.
  String get displayName {
    final name = patientName?.trim();
    return (name == null || name.isEmpty) ? patientId : name;
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
