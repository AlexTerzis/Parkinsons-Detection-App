// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i18;
import 'dart:io' as _i21;
import 'dart:ui' as _i20;

import 'package:flutter/material.dart' as _i17;
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/models/raison_result.dart' as _i19;
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_view.dart'
    as _i6;
import 'package:parkinsondetetion/ui/views/doctor/doctor_view.dart' as _i4;
import 'package:parkinsondetetion/ui/views/drawing_test/camera_draw_view.dart'
    as _i12;
import 'package:parkinsondetetion/ui/views/drawing_test/gallery_draw_view.dart'
    as _i13;
import 'package:parkinsondetetion/ui/views/drawing_test/signature_canvas_view.dart'
    as _i11;
import 'package:parkinsondetetion/ui/views/fab_test/fab_test_view.dart' as _i15;
import 'package:parkinsondetetion/ui/views/insights/insights_view.dart' as _i16;
import 'package:parkinsondetetion/ui/views/login/login_view.dart' as _i3;
import 'package:parkinsondetetion/ui/views/neuro_test/neuro_test_view.dart'
    as _i14;
import 'package:parkinsondetetion/ui/views/patience/patience_view.dart' as _i5;
import 'package:parkinsondetetion/ui/views/questionnaire/questionnaire_view.dart'
    as _i9;
import 'package:parkinsondetetion/ui/views/startup/startup_view.dart' as _i2;
import 'package:parkinsondetetion/ui/views/tap_test/tap_test_view.dart' as _i8;
import 'package:parkinsondetetion/ui/views/tremor_test/tremor_test_view.dart'
    as _i7;
import 'package:parkinsondetetion/ui/views/voice_test/voice_test_view.dart'
    as _i10;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i22;

class Routes {
  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const doctorView = '/doctor-view';

  static const patienceView = '/patience-view';

  static const cameraTestView = '/camera-test-view';

  static const tremorTestView = '/tremor-test-view';

  static const tapTestView = '/tap-test-view';

  static const questionnaireView = '/questionnaire-view';

  static const voiceTestView = '/voice-test-view';

  static const signatureCanvasView = '/signature-canvas-view';

  static const cameraDrawView = '/camera-draw-view';

  static const galleryDrawView = '/gallery-draw-view';

  static const neuroTestView = '/neuro-test-view';

  static const fABTestView = '/f-ab-test-view';

  static const insightsView = '/insights-view';

  static const all = <String>{
    startupView,
    loginView,
    doctorView,
    patienceView,
    cameraTestView,
    tremorTestView,
    tapTestView,
    questionnaireView,
    voiceTestView,
    signatureCanvasView,
    cameraDrawView,
    galleryDrawView,
    neuroTestView,
    fABTestView,
    insightsView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.startupView,
      page: _i2.StartupView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i3.LoginView,
    ),
    _i1.RouteDef(
      Routes.doctorView,
      page: _i4.DoctorView,
    ),
    _i1.RouteDef(
      Routes.patienceView,
      page: _i5.PatienceView,
    ),
    _i1.RouteDef(
      Routes.cameraTestView,
      page: _i6.CameraTestView,
    ),
    _i1.RouteDef(
      Routes.tremorTestView,
      page: _i7.TremorTestView,
    ),
    _i1.RouteDef(
      Routes.tapTestView,
      page: _i8.TapTestView,
    ),
    _i1.RouteDef(
      Routes.questionnaireView,
      page: _i9.QuestionnaireView,
    ),
    _i1.RouteDef(
      Routes.voiceTestView,
      page: _i10.VoiceTestView,
    ),
    _i1.RouteDef(
      Routes.signatureCanvasView,
      page: _i11.SignatureCanvasView,
    ),
    _i1.RouteDef(
      Routes.cameraDrawView,
      page: _i12.CameraDrawView,
    ),
    _i1.RouteDef(
      Routes.galleryDrawView,
      page: _i13.GalleryDrawView,
    ),
    _i1.RouteDef(
      Routes.neuroTestView,
      page: _i14.NeuroTestView,
    ),
    _i1.RouteDef(
      Routes.fABTestView,
      page: _i15.FABTestView,
    ),
    _i1.RouteDef(
      Routes.insightsView,
      page: _i16.InsightsView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.StartupView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i2.StartupView(),
        settings: data,
      );
    },
    _i3.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.LoginView(key: args.key),
        settings: data,
      );
    },
    _i4.DoctorView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i4.DoctorView(),
        settings: data,
      );
    },
    _i5.PatienceView: (data) {
      final args = data.getArgs<PatienceViewArguments>(
        orElse: () => const PatienceViewArguments(),
      );
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.PatienceView(
            key: args.key,
            initialTab: args.initialTab,
            resultsFuture: args.resultsFuture),
        settings: data,
      );
    },
    _i6.CameraTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i6.CameraTestView(),
        settings: data,
      );
    },
    _i7.TremorTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i7.TremorTestView(),
        settings: data,
      );
    },
    _i8.TapTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i8.TapTestView(),
        settings: data,
      );
    },
    _i9.QuestionnaireView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i9.QuestionnaireView(),
        settings: data,
      );
    },
    _i10.VoiceTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i10.VoiceTestView(),
        settings: data,
      );
    },
    _i11.SignatureCanvasView: (data) {
      final args = data.getArgs<SignatureCanvasViewArguments>(nullOk: false);
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.SignatureCanvasView(
            key: args.key, onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i12.CameraDrawView: (data) {
      final args = data.getArgs<CameraDrawViewArguments>(nullOk: false);
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i12.CameraDrawView(key: args.key, onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i13.GalleryDrawView: (data) {
      final args = data.getArgs<GalleryDrawViewArguments>(nullOk: false);
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => _i13.GalleryDrawView(
            key: args.key, onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i14.NeuroTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i14.NeuroTestView(),
        settings: data,
      );
    },
    _i15.FABTestView: (data) {
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) => const _i15.FABTestView(),
        settings: data,
      );
    },
    _i16.InsightsView: (data) {
      final args = data.getArgs<InsightsViewArguments>(nullOk: false);
      return _i17.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i16.InsightsView(key: args.key, results: args.results),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i17.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant LoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class PatienceViewArguments {
  const PatienceViewArguments({
    this.key,
    this.initialTab = 0,
    this.resultsFuture,
  });

  final _i17.Key? key;

  final int initialTab;

  final _i18.Future<List<_i19.RaisonResult>>? resultsFuture;

  @override
  String toString() {
    return '{"key": "$key", "initialTab": "$initialTab", "resultsFuture": "$resultsFuture"}';
  }

  @override
  bool operator ==(covariant PatienceViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.initialTab == initialTab &&
        other.resultsFuture == resultsFuture;
  }

  @override
  int get hashCode {
    return key.hashCode ^ initialTab.hashCode ^ resultsFuture.hashCode;
  }
}

class SignatureCanvasViewArguments {
  const SignatureCanvasViewArguments({
    this.key,
    required this.onImageReady,
  });

  final _i17.Key? key;

  final void Function(_i20.Image) onImageReady;

  @override
  String toString() {
    return '{"key": "$key", "onImageReady": "$onImageReady"}';
  }

  @override
  bool operator ==(covariant SignatureCanvasViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onImageReady == onImageReady;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onImageReady.hashCode;
  }
}

class CameraDrawViewArguments {
  const CameraDrawViewArguments({
    this.key,
    required this.onImageReady,
  });

  final _i17.Key? key;

  final void Function(_i21.File) onImageReady;

  @override
  String toString() {
    return '{"key": "$key", "onImageReady": "$onImageReady"}';
  }

  @override
  bool operator ==(covariant CameraDrawViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onImageReady == onImageReady;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onImageReady.hashCode;
  }
}

class GalleryDrawViewArguments {
  const GalleryDrawViewArguments({
    this.key,
    required this.onImageReady,
  });

  final _i17.Key? key;

  final void Function(_i21.File) onImageReady;

  @override
  String toString() {
    return '{"key": "$key", "onImageReady": "$onImageReady"}';
  }

  @override
  bool operator ==(covariant GalleryDrawViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.onImageReady == onImageReady;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onImageReady.hashCode;
  }
}

class InsightsViewArguments {
  const InsightsViewArguments({
    this.key,
    required this.results,
  });

  final _i17.Key? key;

  final List<_i19.RaisonResult> results;

  @override
  String toString() {
    return '{"key": "$key", "results": "$results"}';
  }

  @override
  bool operator ==(covariant InsightsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.results == results;
  }

  @override
  int get hashCode {
    return key.hashCode ^ results.hashCode;
  }
}

extension NavigatorStateExtension on _i22.NavigationService {
  Future<dynamic> navigateToStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView({
    _i17.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToDoctorView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.doctorView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPatienceView({
    _i17.Key? key,
    int initialTab = 0,
    _i18.Future<List<_i19.RaisonResult>>? resultsFuture,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.patienceView,
        arguments: PatienceViewArguments(
            key: key, initialTab: initialTab, resultsFuture: resultsFuture),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCameraTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.cameraTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToTremorTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.tremorTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToTapTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.tapTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToQuestionnaireView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.questionnaireView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVoiceTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.voiceTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSignatureCanvasView({
    _i17.Key? key,
    required void Function(_i20.Image) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.signatureCanvasView,
        arguments:
            SignatureCanvasViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCameraDrawView({
    _i17.Key? key,
    required void Function(_i21.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.cameraDrawView,
        arguments:
            CameraDrawViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToGalleryDrawView({
    _i17.Key? key,
    required void Function(_i21.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.galleryDrawView,
        arguments:
            GalleryDrawViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToNeuroTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.neuroTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFABTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.fABTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToInsightsView({
    _i17.Key? key,
    required List<_i19.RaisonResult> results,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.insightsView,
        arguments: InsightsViewArguments(key: key, results: results),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.startupView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView({
    _i17.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithDoctorView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.doctorView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPatienceView({
    _i17.Key? key,
    int initialTab = 0,
    _i18.Future<List<_i19.RaisonResult>>? resultsFuture,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.patienceView,
        arguments: PatienceViewArguments(
            key: key, initialTab: initialTab, resultsFuture: resultsFuture),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCameraTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.cameraTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithTremorTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.tremorTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithTapTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.tapTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithQuestionnaireView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.questionnaireView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVoiceTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.voiceTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSignatureCanvasView({
    _i17.Key? key,
    required void Function(_i20.Image) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.signatureCanvasView,
        arguments:
            SignatureCanvasViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCameraDrawView({
    _i17.Key? key,
    required void Function(_i21.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.cameraDrawView,
        arguments:
            CameraDrawViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithGalleryDrawView({
    _i17.Key? key,
    required void Function(_i21.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.galleryDrawView,
        arguments:
            GalleryDrawViewArguments(key: key, onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithNeuroTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.neuroTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFABTestView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.fABTestView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithInsightsView({
    _i17.Key? key,
    required List<_i19.RaisonResult> results,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.insightsView,
        arguments: InsightsViewArguments(key: key, results: results),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
