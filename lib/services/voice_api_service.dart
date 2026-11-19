import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Descriptive measurements from this recording, independent of diagnosis.
class VoiceAcousticAnalysis {
  const VoiceAcousticAnalysis({
    required this.overallScore,
    required this.pitchSteadiness,
    required this.amplitudeSteadiness,
    required this.tonalClarity,
    required this.sustainQuality,
    required this.meanPitchHz,
    required this.jitterPercent,
    required this.shimmerPercent,
    required this.hnrDb,
    required this.voicedFraction,
  });

  final double overallScore;
  final double pitchSteadiness;
  final double amplitudeSteadiness;
  final double tonalClarity;
  final double sustainQuality;
  final double meanPitchHz;
  final double jitterPercent;
  final double shimmerPercent;
  final double hnrDb;
  final double voicedFraction;

  static VoiceAcousticAnalysis? fromResponse(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final rawQuality = json['input_quality'];
    if (rawFeatures is! Map || rawQuality is! Map) return null;

    final features = Map<String, dynamic>.from(rawFeatures);
    final quality = Map<String, dynamic>.from(rawQuality);
    final rawZScores = quality['z_scores'];
    if (rawZScores is! Map) return null;
    final zScores = Map<String, dynamic>.from(rawZScores);

    double? number(Map<String, dynamic> values, String key) =>
        values[key] is num ? (values[key] as num).toDouble() : null;

    final meanPitch = number(features, 'MDVP:Fo(Hz)');
    final jitter = number(features, 'MDVP:Jitter(%)');
    final shimmer = number(features, 'MDVP:Shimmer');
    final hnr = number(features, 'HNR');
    final jitterZ = number(zScores, 'MDVP:Jitter(%)');
    final shimmerZ = number(zScores, 'MDVP:Shimmer');
    final hnrZ = number(zScores, 'HNR');
    final duration = number(quality, 'duration_seconds');
    final voiced = number(quality, 'voiced_fraction');
    final clipped = number(quality, 'clipped_fraction');

    if ([
      meanPitch,
      jitter,
      shimmer,
      hnr,
      jitterZ,
      shimmerZ,
      hnrZ,
      duration,
      voiced,
      clipped,
    ].any((value) => value == null || !value.isFinite)) {
      return null;
    }
    if (duration! < 4 || voiced! < .55 || clipped! > .01) return null;

    // These are descriptive transforms, not disease probabilities. Jitter and
    // shimmer reward steadiness, HNR rewards tonal clarity, and sustained voice
    // is measured directly. Z-scores only establish a visual scale against the
    // small research reference set.
    double sigmoid(double value) {
      final bounded = value.clamp(-8.0, 8.0).toDouble();
      return 1 / (1 + math.exp(-bounded));
    }

    final pitchSteadiness = sigmoid(-jitterZ!);
    final amplitudeSteadiness = sigmoid(-shimmerZ!);
    final tonalClarity = sigmoid(hnrZ!);
    final sustainQuality = ((voiced - .55) / .4).clamp(0.0, 1.0).toDouble();
    final overall = (.30 * pitchSteadiness +
            .30 * amplitudeSteadiness +
            .25 * tonalClarity +
            .15 * sustainQuality)
        .clamp(0.0, 1.0)
        .toDouble();

    return VoiceAcousticAnalysis(
      overallScore: overall,
      pitchSteadiness: pitchSteadiness,
      amplitudeSteadiness: amplitudeSteadiness,
      tonalClarity: tonalClarity,
      sustainQuality: sustainQuality,
      meanPitchHz: meanPitch!,
      jitterPercent: jitter! * 100,
      shimmerPercent: shimmer! * 100,
      hnrDb: hnr!,
      voicedFraction: voiced,
    );
  }
}

/// A versioned response from the sustained-vowel research service.
///
/// [screeningScore] is deliberately nullable. When a recording is outside the
/// model's reference distribution, returning no score is safer than presenting
/// an extrapolated value as a confident health result.
class VoicePrediction {
  const VoicePrediction({
    required this.status,
    required this.modelVersion,
    required this.screeningScore,
    required this.decisionThreshold,
    required this.warnings,
    required this.validatedForClinicalUse,
    required this.acousticAnalysis,
    required this.experimentalModelScore,
  });

  final String status;
  final String? modelVersion;
  final double? screeningScore;
  final double decisionThreshold;
  final List<String> warnings;
  final bool validatedForClinicalUse;
  final VoiceAcousticAnalysis? acousticAnalysis;
  final double? experimentalModelScore;

  bool get isUsable =>
      validatedForClinicalUse &&
      status == 'ok' &&
      modelVersion != null &&
      screeningScore != null;

  factory VoicePrediction.fromJson(Map<String, dynamic> json) {
    final modelVersion = json['model_version'] as String?;
    final inputQuality = json['input_quality'];
    final quality = inputQuality is Map
        ? Map<String, dynamic>.from(inputQuality)
        : const <String, dynamic>{};
    final rawWarnings = quality['warnings'];
    final warnings = rawWarnings is List
        ? rawWarnings.whereType<String>().toList(growable: false)
        : const <String>[];

    // Responses from the original endpoint had no version or validity flag.
    // Treat them as inconclusive so an old deployment cannot keep surfacing
    // the known, unit-mismatched 99% result.
    if (modelVersion == null) {
      return const VoicePrediction(
        status: 'legacy_model',
        modelVersion: null,
        screeningScore: null,
        decisionThreshold: .7,
        warnings: <String>['voice_service_update_required'],
        validatedForClinicalUse: false,
        acousticAnalysis: null,
        experimentalModelScore: null,
      );
    }

    final validatedForClinicalUse = json['validated_for_clinical_use'] == true;
    final rawStatus = json['result_status'] as String? ?? 'invalid_response';
    final rawScore = json['screening_score'];
    final score = validatedForClinicalUse && rawScore is num
        ? rawScore.toDouble().clamp(0.0, 1.0).toDouble()
        : null;
    final rawThreshold = json['decision_threshold'];
    final rawExperimentalScore = json['experimental_model_score'];

    return VoicePrediction(
      status: !validatedForClinicalUse && rawStatus == 'ok'
          ? 'research_model_not_validated'
          : rawStatus,
      modelVersion: modelVersion,
      screeningScore: score,
      decisionThreshold: rawThreshold is num
          ? rawThreshold.toDouble().clamp(0.0, 1.0).toDouble()
          : .7,
      warnings: warnings,
      validatedForClinicalUse: validatedForClinicalUse,
      acousticAnalysis: VoiceAcousticAnalysis.fromResponse(json),
      experimentalModelScore: rawExperimentalScore is num
          ? rawExperimentalScore.toDouble().clamp(0.0, 1.0).toDouble()
          : null,
    );
  }
}

/// Talks to the Python model hosted on Render.
class VoiceApiService {
  static const String _baseUrl = 'https://pd-voice-detector.onrender.com';

  Future<VoicePrediction> predict(File wav) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', wav.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Prediction failed: ${response.statusCode}');
    }

    final String body = await response.stream.bytesToString();
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid voice-service response');
    }
    return VoicePrediction.fromJson(data);
  }
}
