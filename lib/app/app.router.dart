// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i19;
import 'dart:io' as _i22;
import 'dart:ui' as _i21;

import 'package:flutter/material.dart' as _i18;
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/models/raison_result.dart' as _i20;
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_view.dart'
    as _i6;
import 'package:parkinsondetetion/ui/views/doctor/doctor_view.dart' as _i4;
import 'package:parkinsondetetion/ui/views/drawing_test/camera_draw_view.dart'
    as _i13;
import 'package:parkinsondetetion/ui/views/drawing_test/gallery_draw_view.dart'
    as _i14;
import 'package:parkinsondetetion/ui/views/drawing_test/signature_canvas_view.dart'
    as _i12;
import 'package:parkinsondetetion/ui/views/fab_test/fab_test_view.dart' as _i16;
import 'package:parkinsondetetion/ui/views/insights/insights_view.dart' as _i17;
import 'package:parkinsondetetion/ui/views/login/login_view.dart' as _i3;
import 'package:parkinsondetetion/ui/views/neuro_test/neuro_test_view.dart'
    as _i15;
import 'package:parkinsondetetion/ui/views/patience/patience_view.dart' as _i5;
import 'package:parkinsondetetion/ui/views/posture_test/posture_test_view.dart'
    as _i7;
import 'package:parkinsondetetion/ui/views/questionnaire/questionnaire_view.dart'
    as _i10;
import 'package:parkinsondetetion/ui/views/startup/startup_view.dart' as _i2;
import 'package:parkinsondetetion/ui/views/tap_test/tap_test_view.dart' as _i9;
import 'package:parkinsondetetion/ui/views/tremor_test/tremor_test_view.dart'
    as _i8;
import 'package:parkinsondetetion/ui/views/voice_test/voice_test_view.dart'
    as _i11;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i23;

class Routes {
  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const doctorView = '/doctor-view';

  static const patienceView = '/patience-view';

  static const cameraTestView = '/camera-test-view';

  static const postureTestView = '/posture-test-view';

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
    postureTestView,
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
      Routes.postureTestView,
      page: _i7.PostureTestView,
    ),
    _i1.RouteDef(
      Routes.tremorTestView,
      page: _i8.TremorTestView,
    ),
    _i1.RouteDef(
      Routes.tapTestView,
      page: _i9.TapTestView,
    ),
    _i1.RouteDef(
      Routes.questionnaireView,
      page: _i10.QuestionnaireView,
    ),
    _i1.RouteDef(
      Routes.voiceTestView,
      page: _i11.VoiceTestView,
    ),
    _i1.RouteDef(
      Routes.signatureCanvasView,
      page: _i12.SignatureCanvasView,
    ),
    _i1.RouteDef(
      Routes.cameraDrawView,
      page: _i13.CameraDrawView,
    ),
    _i1.RouteDef(
      Routes.galleryDrawView,
      page: _i14.GalleryDrawView,
    ),
    _i1.RouteDef(
      Routes.neuroTestView,
      page: _i15.NeuroTestView,
    ),
    _i1.RouteDef(
      Routes.fABTestView,
      page: _i16.FABTestView,
    ),
    _i1.RouteDef(
      Routes.insightsView,
      page: _i17.InsightsView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.StartupView(key: args.key),
        settings: data,
      );
    },
    _i3.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.LoginView(key: args.key),
        settings: data,
      );
    },
    _i4.DoctorView: (data) {
      final args = data.getArgs<DoctorViewArguments>(
        orElse: () => const DoctorViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.DoctorView(key: args.key),
        settings: data,
      );
    },
    _i5.PatienceView: (data) {
      final args = data.getArgs<PatienceViewArguments>(
        orElse: () => const PatienceViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.PatienceView(
            key: args.key,
            initialTab: args.initialTab,
            resultsFuture: args.resultsFuture),
        settings: data,
      );
    },
    _i6.CameraTestView: (data) {
      final args = data.getArgs<CameraTestViewArguments>(
        orElse: () => const CameraTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i6.CameraTestView(key: args.key),
        settings: data,
      );
    },
    _i7.PostureTestView: (data) {
      final args = data.getArgs<PostureTestViewArguments>(
        orElse: () => const PostureTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i7.PostureTestView(key: args.key),
        settings: data,
      );
    },
    _i8.TremorTestView: (data) {
      final args = data.getArgs<TremorTestViewArguments>(
        orElse: () => const TremorTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i8.TremorTestView(key: args.key),
        settings: data,
      );
    },
    _i9.TapTestView: (data) {
      final args = data.getArgs<TapTestViewArguments>(
        orElse: () => const TapTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i9.TapTestView(key: args.key),
        settings: data,
      );
    },
    _i10.QuestionnaireView: (data) {
      final args = data.getArgs<QuestionnaireViewArguments>(
        orElse: () => const QuestionnaireViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i10.QuestionnaireView(key: args.key),
        settings: data,
      );
    },
    _i11.VoiceTestView: (data) {
      final args = data.getArgs<VoiceTestViewArguments>(
        orElse: () => const VoiceTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.VoiceTestView(key: args.key),
        settings: data,
      );
    },
    _i12.SignatureCanvasView: (data) {
      final args = data.getArgs<SignatureCanvasViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i12.SignatureCanvasView(
            key: args.key,
            onImageReady: args.onImageReady,
            drawingType: args.drawingType,
            onAnalyze: args.onAnalyze),
        settings: data,
      );
    },
    _i13.CameraDrawView: (data) {
      final args = data.getArgs<CameraDrawViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i13.CameraDrawView(key: args.key, onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i14.GalleryDrawView: (data) {
      final args = data.getArgs<GalleryDrawViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i14.GalleryDrawView(
            key: args.key, onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i15.NeuroTestView: (data) {
      final args = data.getArgs<NeuroTestViewArguments>(
        orElse: () => const NeuroTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i15.NeuroTestView(key: args.key),
        settings: data,
      );
    },
    _i16.FABTestView: (data) {
      final args = data.getArgs<FABTestViewArguments>(
        orElse: () => const FABTestViewArguments(),
      );
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) => _i16.FABTestView(key: args.key),
        settings: data,
      );
    },
    _i17.InsightsView: (data) {
      final args = data.getArgs<InsightsViewArguments>(nullOk: false);
      return _i18.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i17.InsightsView(key: args.key, results: args.results),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i18.Key? key;

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

class DoctorViewArguments {
  const DoctorViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant DoctorViewArguments other) {
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

  final _i18.Key? key;

  final int initialTab;

  final _i19.Future<List<_i20.RaisonResult>>? resultsFuture;

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

class CameraTestViewArguments {
  const CameraTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant CameraTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class PostureTestViewArguments {
  const PostureTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant PostureTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class TremorTestViewArguments {
  const TremorTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant TremorTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class TapTestViewArguments {
  const TapTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant TapTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class QuestionnaireViewArguments {
  const QuestionnaireViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant QuestionnaireViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VoiceTestViewArguments {
  const VoiceTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VoiceTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class SignatureCanvasViewArguments {
  const SignatureCanvasViewArguments({
    this.key,
    required this.onImageReady,
    this.drawingType = 'spiral',
    this.onAnalyze,
  });

  final _i18.Key? key;

  final void Function(_i21.Image) onImageReady;

  final String drawingType;

  final _i19.Future<void> Function(_i21.Image)? onAnalyze;

  @override
  String toString() {
    return '{"key": "$key", "onImageReady": "$onImageReady", "drawingType": "$drawingType", "onAnalyze": "$onAnalyze"}';
  }

  @override
  bool operator ==(covariant SignatureCanvasViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.onImageReady == onImageReady &&
        other.drawingType == drawingType &&
        other.onAnalyze == onAnalyze;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        onImageReady.hashCode ^
        drawingType.hashCode ^
        onAnalyze.hashCode;
  }
}

class CameraDrawViewArguments {
  const CameraDrawViewArguments({
    this.key,
    required this.onImageReady,
  });

  final _i18.Key? key;

  final void Function(_i22.File) onImageReady;

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

  final _i18.Key? key;

  final void Function(_i22.File) onImageReady;

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

class NeuroTestViewArguments {
  const NeuroTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant NeuroTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class FABTestViewArguments {
  const FABTestViewArguments({this.key});

  final _i18.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant FABTestViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class InsightsViewArguments {
  const InsightsViewArguments({
    this.key,
    required this.results,
  });

  final _i18.Key? key;

  final List<_i20.RaisonResult> results;

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

extension NavigatorStateExtension on _i23.NavigationService {
  Future<dynamic> navigateToStartupView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView({
    _i18.Key? key,
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

  Future<dynamic> navigateToDoctorView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.doctorView,
        arguments: DoctorViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPatienceView({
    _i18.Key? key,
    int initialTab = 0,
    _i19.Future<List<_i20.RaisonResult>>? resultsFuture,
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

  Future<dynamic> navigateToCameraTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.cameraTestView,
        arguments: CameraTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPostureTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.postureTestView,
        arguments: PostureTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToTremorTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.tremorTestView,
        arguments: TremorTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToTapTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.tapTestView,
        arguments: TapTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToQuestionnaireView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.questionnaireView,
        arguments: QuestionnaireViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVoiceTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.voiceTestView,
        arguments: VoiceTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSignatureCanvasView({
    _i18.Key? key,
    required void Function(_i21.Image) onImageReady,
    String drawingType = 'spiral',
    _i19.Future<void> Function(_i21.Image)? onAnalyze,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.signatureCanvasView,
        arguments: SignatureCanvasViewArguments(
            key: key,
            onImageReady: onImageReady,
            drawingType: drawingType,
            onAnalyze: onAnalyze),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCameraDrawView({
    _i18.Key? key,
    required void Function(_i22.File) onImageReady,
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
    _i18.Key? key,
    required void Function(_i22.File) onImageReady,
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

  Future<dynamic> navigateToNeuroTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.neuroTestView,
        arguments: NeuroTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToFABTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.fABTestView,
        arguments: FABTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToInsightsView({
    _i18.Key? key,
    required List<_i20.RaisonResult> results,
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

  Future<dynamic> replaceWithStartupView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView({
    _i18.Key? key,
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

  Future<dynamic> replaceWithDoctorView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.doctorView,
        arguments: DoctorViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPatienceView({
    _i18.Key? key,
    int initialTab = 0,
    _i19.Future<List<_i20.RaisonResult>>? resultsFuture,
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

  Future<dynamic> replaceWithCameraTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.cameraTestView,
        arguments: CameraTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPostureTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.postureTestView,
        arguments: PostureTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithTremorTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.tremorTestView,
        arguments: TremorTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithTapTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.tapTestView,
        arguments: TapTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithQuestionnaireView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.questionnaireView,
        arguments: QuestionnaireViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVoiceTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.voiceTestView,
        arguments: VoiceTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSignatureCanvasView({
    _i18.Key? key,
    required void Function(_i21.Image) onImageReady,
    String drawingType = 'spiral',
    _i19.Future<void> Function(_i21.Image)? onAnalyze,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.signatureCanvasView,
        arguments: SignatureCanvasViewArguments(
            key: key,
            onImageReady: onImageReady,
            drawingType: drawingType,
            onAnalyze: onAnalyze),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCameraDrawView({
    _i18.Key? key,
    required void Function(_i22.File) onImageReady,
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
    _i18.Key? key,
    required void Function(_i22.File) onImageReady,
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

  Future<dynamic> replaceWithNeuroTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.neuroTestView,
        arguments: NeuroTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithFABTestView({
    _i18.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.fABTestView,
        arguments: FABTestViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithInsightsView({
    _i18.Key? key,
    required List<_i20.RaisonResult> results,
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
