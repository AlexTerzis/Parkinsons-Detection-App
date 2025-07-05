// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i8;
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_view.dart'
    as _i7;
import 'package:parkinsondetetion/ui/views/doctor/doctor_view.dart' as _i5;
import 'package:parkinsondetetion/ui/views/home/home_view.dart' as _i2;
import 'package:parkinsondetetion/ui/views/login/login_view.dart' as _i4;
import 'package:parkinsondetetion/ui/views/patience/patience_view.dart' as _i6;
import 'package:parkinsondetetion/ui/views/startup/startup_view.dart' as _i3;
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i9;
import 'dart:io' as _i10;
import 'package:parkinsondetetion/ui/views/drawing_test/signature_canvas_view.dart' as _i11;
import 'package:parkinsondetetion/ui/views/drawing_test/camera_draw_view.dart' as _i12;
import 'package:parkinsondetetion/ui/views/drawing_test/gallery_draw_view.dart' as _i13;
import 'dart:ui' as _i14;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const loginView = '/login-view';

  static const doctorView = '/doctor-view';

  static const patienceView = '/patience-view';

  static const cameraTestView = '/camera-test-view';

  static const signatureCanvasView = '/signature-canvas-view';

  static const cameraDrawView = '/camera-draw-view';

  static const galleryDrawView = '/gallery-draw-view';

  static const all = <String>{
    homeView,
    startupView,
    loginView,
    doctorView,
    patienceView,
    cameraTestView,
    signatureCanvasView,
    cameraDrawView,
    galleryDrawView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i4.LoginView,
    ),
    _i1.RouteDef(
      Routes.doctorView,
      page: _i5.DoctorView,
    ),
    _i1.RouteDef(
      Routes.patienceView,
      page: _i6.PatienceView,
    ),
    _i1.RouteDef(
      Routes.cameraTestView,
      page: _i7.CameraTestView,
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
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => const _i2.HomeView(),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => const _i3.StartupView(),
        settings: data,
      );
    },
    _i4.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.LoginView(key: args.key),
        settings: data,
      );
    },
    _i5.DoctorView: (data) {
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => const _i5.DoctorView(),
        settings: data,
      );
    },
    _i6.PatienceView: (data) {
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => const _i6.PatienceView(),
        settings: data,
      );
    },
    _i7.CameraTestView: (data) {
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => const _i7.CameraTestView(),
        settings: data,
      );
    },
    _i11.SignatureCanvasView: (data) {
      final args = data.getArgs<SignatureCanvasViewArguments>(
        orElse: () => throw ArgumentError('args'),
      );
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.SignatureCanvasView(onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i12.CameraDrawView: (data) {
      final args = data.getArgs<CameraDrawViewArguments>(
        orElse: () => throw ArgumentError('args'),
      );
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => _i12.CameraDrawView(onImageReady: args.onImageReady),
        settings: data,
      );
    },
    _i13.GalleryDrawView: (data) {
      final args = data.getArgs<GalleryDrawViewArguments>(
        orElse: () => throw ArgumentError('args'),
      );
      return _i8.MaterialPageRoute<dynamic>(
        builder: (context) => _i13.GalleryDrawView(onImageReady: args.onImageReady),
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

  final _i8.Key? key;

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

class SignatureCanvasViewArguments {
  const SignatureCanvasViewArguments({required this.onImageReady});

  final void Function(_i14.Image) onImageReady;

  @override
  bool operator ==(covariant SignatureCanvasViewArguments other) {
    return identical(this, other) || other.onImageReady == onImageReady;
  }

  @override
  int get hashCode => onImageReady.hashCode;
}

class CameraDrawViewArguments {
  const CameraDrawViewArguments({required this.onImageReady});

  final void Function(_i10.File) onImageReady;

  @override
  bool operator ==(covariant CameraDrawViewArguments other) {
    return identical(this, other) || other.onImageReady == onImageReady;
  }

  @override
  int get hashCode => onImageReady.hashCode;
}

class GalleryDrawViewArguments {
  const GalleryDrawViewArguments({required this.onImageReady});

  final void Function(_i10.File) onImageReady;

  @override
  bool operator ==(covariant GalleryDrawViewArguments other) {
    return identical(this, other) || other.onImageReady == onImageReady;
  }

  @override
  int get hashCode => onImageReady.hashCode;
}

extension NavigatorStateExtension on _i9.NavigationService {
  Future<dynamic> navigateToHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.homeView,
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

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
    _i8.Key? key,
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

  Future<dynamic> navigateToPatienceView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return navigateTo<dynamic>(Routes.patienceView,
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

  Future<dynamic> navigateToSignatureCanvasView({
    required void Function(_i14.Image) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.signatureCanvasView,
        arguments: SignatureCanvasViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCameraDrawView({
    required void Function(_i10.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.cameraDrawView,
        arguments: CameraDrawViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToGalleryDrawView({
    required void Function(_i10.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.galleryDrawView,
        arguments: GalleryDrawViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.homeView,
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
    _i8.Key? key,
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

  Future<dynamic> replaceWithPatienceView([
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  ]) async {
    return replaceWith<dynamic>(Routes.patienceView,
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

  Future<dynamic> replaceWithSignatureCanvasView({
    required void Function(_i14.Image) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.signatureCanvasView,
        arguments: SignatureCanvasViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCameraDrawView({
    required void Function(_i10.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.cameraDrawView,
        arguments: CameraDrawViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithGalleryDrawView({
    required void Function(_i10.File) onImageReady,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.galleryDrawView,
        arguments: GalleryDrawViewArguments(onImageReady: onImageReady),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
