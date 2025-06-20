// Mocks generated by Mockito 5.4.5 from annotations
// in parkinsondetetion/test/helpers/test_helpers.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;
import 'dart:ui' as _i7;

import 'package:firebase_auth/firebase_auth.dart' as _i2;
import 'package:flutter/material.dart' as _i5;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i4;
import 'package:parkinsondetetion/models/app_user.dart' as _i12;
import 'package:parkinsondetetion/models/doctor_note.dart' as _i14;
import 'package:parkinsondetetion/models/patient_report.dart' as _i13;
import 'package:parkinsondetetion/models/test_result.dart' as _i10;
import 'package:parkinsondetetion/services/authentication_service.dart' as _i8;
import 'package:parkinsondetetion/services/reports_service.dart' as _i11;
import 'package:parkinsondetetion/services/test_service.dart' as _i9;
import 'package:stacked_services/stacked_services.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUserCredential_0 extends _i1.SmartFake
    implements _i2.UserCredential {
  _FakeUserCredential_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [NavigationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNavigationService extends _i1.Mock implements _i3.NavigationService {
  @override
  String get previousRoute => (super.noSuchMethod(
        Invocation.getter(#previousRoute),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.getter(#previousRoute),
        ),
        returnValueForMissingStub: _i4.dummyValue<String>(
          this,
          Invocation.getter(#previousRoute),
        ),
      ) as String);

  @override
  String get currentRoute => (super.noSuchMethod(
        Invocation.getter(#currentRoute),
        returnValue: _i4.dummyValue<String>(
          this,
          Invocation.getter(#currentRoute),
        ),
        returnValueForMissingStub: _i4.dummyValue<String>(
          this,
          Invocation.getter(#currentRoute),
        ),
      ) as String);

  @override
  _i5.GlobalKey<_i5.NavigatorState>? nestedNavigationKey(int? index) =>
      (super.noSuchMethod(
        Invocation.method(
          #nestedNavigationKey,
          [index],
        ),
        returnValueForMissingStub: null,
      ) as _i5.GlobalKey<_i5.NavigatorState>?);

  @override
  void config({
    bool? enableLog,
    bool? defaultPopGesture,
    bool? defaultOpaqueRoute,
    Duration? defaultDurationTransition,
    bool? defaultGlobalState,
    _i3.Transition? defaultTransitionStyle,
    String? defaultTransition,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #config,
          [],
          {
            #enableLog: enableLog,
            #defaultPopGesture: defaultPopGesture,
            #defaultOpaqueRoute: defaultOpaqueRoute,
            #defaultDurationTransition: defaultDurationTransition,
            #defaultGlobalState: defaultGlobalState,
            #defaultTransitionStyle: defaultTransitionStyle,
            #defaultTransition: defaultTransition,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<T?>? navigateWithTransition<T>(
    _i5.Widget? page, {
    bool? opaque,
    String? transition = '',
    Duration? duration,
    bool? popGesture,
    int? id,
    _i5.Curve? curve,
    bool? fullscreenDialog = false,
    bool? preventDuplicates = true,
    _i3.Transition? transitionClass,
    _i3.Transition? transitionStyle,
    String? routeName,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #navigateWithTransition,
          [page],
          {
            #opaque: opaque,
            #transition: transition,
            #duration: duration,
            #popGesture: popGesture,
            #id: id,
            #curve: curve,
            #fullscreenDialog: fullscreenDialog,
            #preventDuplicates: preventDuplicates,
            #transitionClass: transitionClass,
            #transitionStyle: transitionStyle,
            #routeName: routeName,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? replaceWithTransition<T>(
    _i5.Widget? page, {
    bool? opaque,
    String? transition = '',
    Duration? duration,
    bool? popGesture,
    int? id,
    _i5.Curve? curve,
    bool? fullscreenDialog = false,
    bool? preventDuplicates = true,
    _i3.Transition? transitionClass,
    _i3.Transition? transitionStyle,
    String? routeName,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #replaceWithTransition,
          [page],
          {
            #opaque: opaque,
            #transition: transition,
            #duration: duration,
            #popGesture: popGesture,
            #id: id,
            #curve: curve,
            #fullscreenDialog: fullscreenDialog,
            #preventDuplicates: preventDuplicates,
            #transitionClass: transitionClass,
            #transitionStyle: transitionStyle,
            #routeName: routeName,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  bool back<T>({
    dynamic result,
    int? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #back,
          [],
          {
            #result: result,
            #id: id,
          },
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  void popUntil(
    _i5.RoutePredicate? predicate, {
    int? id,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #popUntil,
          [predicate],
          {#id: id},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void popRepeated(int? popTimes) => super.noSuchMethod(
        Invocation.method(
          #popRepeated,
          [popTimes],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<T?>? navigateTo<T>(
    String? routeName, {
    dynamic arguments,
    int? id,
    bool? preventDuplicates = true,
    Map<String, String>? parameters,
    _i5.RouteTransitionsBuilder? transition,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #navigateTo,
          [routeName],
          {
            #arguments: arguments,
            #id: id,
            #preventDuplicates: preventDuplicates,
            #parameters: parameters,
            #transition: transition,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? navigateToView<T>(
    _i5.Widget? view, {
    dynamic arguments,
    int? id,
    bool? opaque,
    _i5.Curve? curve,
    Duration? duration,
    bool? fullscreenDialog = false,
    bool? popGesture,
    bool? preventDuplicates = true,
    _i3.Transition? transition,
    _i3.Transition? transitionStyle,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #navigateToView,
          [view],
          {
            #arguments: arguments,
            #id: id,
            #opaque: opaque,
            #curve: curve,
            #duration: duration,
            #fullscreenDialog: fullscreenDialog,
            #popGesture: popGesture,
            #preventDuplicates: preventDuplicates,
            #transition: transition,
            #transitionStyle: transitionStyle,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? replaceWith<T>(
    String? routeName, {
    dynamic arguments,
    int? id,
    bool? preventDuplicates = true,
    Map<String, String>? parameters,
    _i5.RouteTransitionsBuilder? transition,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #replaceWith,
          [routeName],
          {
            #arguments: arguments,
            #id: id,
            #preventDuplicates: preventDuplicates,
            #parameters: parameters,
            #transition: transition,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? clearStackAndShow<T>(
    String? routeName, {
    dynamic arguments,
    int? id,
    Map<String, String>? parameters,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #clearStackAndShow,
          [routeName],
          {
            #arguments: arguments,
            #id: id,
            #parameters: parameters,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? clearStackAndShowView<T>(
    _i5.Widget? view, {
    dynamic arguments,
    int? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #clearStackAndShowView,
          [view],
          {
            #arguments: arguments,
            #id: id,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? clearTillFirstAndShow<T>(
    String? routeName, {
    dynamic arguments,
    int? id,
    bool? preventDuplicates = true,
    Map<String, String>? parameters,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #clearTillFirstAndShow,
          [routeName],
          {
            #arguments: arguments,
            #id: id,
            #preventDuplicates: preventDuplicates,
            #parameters: parameters,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? clearTillFirstAndShowView<T>(
    _i5.Widget? view, {
    dynamic arguments,
    int? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #clearTillFirstAndShowView,
          [view],
          {
            #arguments: arguments,
            #id: id,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);

  @override
  _i6.Future<T?>? pushNamedAndRemoveUntil<T>(
    String? routeName, {
    _i5.RoutePredicate? predicate,
    dynamic arguments,
    int? id,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #pushNamedAndRemoveUntil,
          [routeName],
          {
            #predicate: predicate,
            #arguments: arguments,
            #id: id,
          },
        ),
        returnValueForMissingStub: null,
      ) as _i6.Future<T?>?);
}

/// A class which mocks [BottomSheetService].
///
/// See the documentation for Mockito's code generation for more information.
class MockBottomSheetService extends _i1.Mock
    implements _i3.BottomSheetService {
  @override
  void setCustomSheetBuilders(Map<dynamic, _i3.SheetBuilder>? builders) =>
      super.noSuchMethod(
        Invocation.method(
          #setCustomSheetBuilders,
          [builders],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i3.SheetResponse<dynamic>?> showBottomSheet({
    required String? title,
    String? description,
    String? confirmButtonTitle = 'Ok',
    String? cancelButtonTitle,
    bool? enableDrag = true,
    bool? barrierDismissible = true,
    bool? isScrollControlled = false,
    Duration? exitBottomSheetDuration,
    Duration? enterBottomSheetDuration,
    bool? ignoreSafeArea,
    bool? useRootNavigator = false,
    double? elevation = 1.0,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #showBottomSheet,
          [],
          {
            #title: title,
            #description: description,
            #confirmButtonTitle: confirmButtonTitle,
            #cancelButtonTitle: cancelButtonTitle,
            #enableDrag: enableDrag,
            #barrierDismissible: barrierDismissible,
            #isScrollControlled: isScrollControlled,
            #exitBottomSheetDuration: exitBottomSheetDuration,
            #enterBottomSheetDuration: enterBottomSheetDuration,
            #ignoreSafeArea: ignoreSafeArea,
            #useRootNavigator: useRootNavigator,
            #elevation: elevation,
          },
        ),
        returnValue: _i6.Future<_i3.SheetResponse<dynamic>?>.value(),
        returnValueForMissingStub:
            _i6.Future<_i3.SheetResponse<dynamic>?>.value(),
      ) as _i6.Future<_i3.SheetResponse<dynamic>?>);

  @override
  _i6.Future<_i3.SheetResponse<T>?> showCustomSheet<T, R>({
    dynamic variant,
    String? title,
    String? description,
    bool? hasImage = false,
    String? imageUrl,
    bool? showIconInMainButton = false,
    String? mainButtonTitle,
    bool? showIconInSecondaryButton = false,
    String? secondaryButtonTitle,
    bool? showIconInAdditionalButton = false,
    String? additionalButtonTitle,
    bool? takesInput = false,
    _i7.Color? barrierColor = const _i7.Color(2315255808),
    double? elevation = 1.0,
    bool? barrierDismissible = true,
    bool? isScrollControlled = false,
    String? barrierLabel = '',
    dynamic customData,
    R? data,
    bool? enableDrag = true,
    Duration? exitBottomSheetDuration,
    Duration? enterBottomSheetDuration,
    bool? ignoreSafeArea,
    bool? useRootNavigator = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #showCustomSheet,
          [],
          {
            #variant: variant,
            #title: title,
            #description: description,
            #hasImage: hasImage,
            #imageUrl: imageUrl,
            #showIconInMainButton: showIconInMainButton,
            #mainButtonTitle: mainButtonTitle,
            #showIconInSecondaryButton: showIconInSecondaryButton,
            #secondaryButtonTitle: secondaryButtonTitle,
            #showIconInAdditionalButton: showIconInAdditionalButton,
            #additionalButtonTitle: additionalButtonTitle,
            #takesInput: takesInput,
            #barrierColor: barrierColor,
            #elevation: elevation,
            #barrierDismissible: barrierDismissible,
            #isScrollControlled: isScrollControlled,
            #barrierLabel: barrierLabel,
            #customData: customData,
            #data: data,
            #enableDrag: enableDrag,
            #exitBottomSheetDuration: exitBottomSheetDuration,
            #enterBottomSheetDuration: enterBottomSheetDuration,
            #ignoreSafeArea: ignoreSafeArea,
            #useRootNavigator: useRootNavigator,
          },
        ),
        returnValue: _i6.Future<_i3.SheetResponse<T>?>.value(),
        returnValueForMissingStub: _i6.Future<_i3.SheetResponse<T>?>.value(),
      ) as _i6.Future<_i3.SheetResponse<T>?>);

  @override
  void completeSheet(_i3.SheetResponse<dynamic>? response) =>
      super.noSuchMethod(
        Invocation.method(
          #completeSheet,
          [response],
        ),
        returnValueForMissingStub: null,
      );
}

/// A class which mocks [DialogService].
///
/// See the documentation for Mockito's code generation for more information.
class MockDialogService extends _i1.Mock implements _i3.DialogService {
  @override
  void registerCustomDialogBuilders(
          Map<dynamic, _i3.DialogBuilder>? builders) =>
      super.noSuchMethod(
        Invocation.method(
          #registerCustomDialogBuilders,
          [builders],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void registerCustomDialogBuilder({
    required dynamic variant,
    required _i5.Widget Function(
      _i5.BuildContext,
      _i3.DialogRequest<dynamic>,
      dynamic Function(_i3.DialogResponse<dynamic>),
    )? builder,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #registerCustomDialogBuilder,
          [],
          {
            #variant: variant,
            #builder: builder,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i3.DialogResponse<dynamic>?> showDialog({
    String? title,
    String? description,
    String? cancelTitle,
    _i7.Color? cancelTitleColor,
    String? buttonTitle = 'Ok',
    _i7.Color? buttonTitleColor,
    bool? barrierDismissible = false,
    _i5.RouteSettings? routeSettings,
    _i5.GlobalKey<_i5.NavigatorState>? navigatorKey,
    _i3.DialogPlatform? dialogPlatform,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #showDialog,
          [],
          {
            #title: title,
            #description: description,
            #cancelTitle: cancelTitle,
            #cancelTitleColor: cancelTitleColor,
            #buttonTitle: buttonTitle,
            #buttonTitleColor: buttonTitleColor,
            #barrierDismissible: barrierDismissible,
            #routeSettings: routeSettings,
            #navigatorKey: navigatorKey,
            #dialogPlatform: dialogPlatform,
          },
        ),
        returnValue: _i6.Future<_i3.DialogResponse<dynamic>?>.value(),
        returnValueForMissingStub:
            _i6.Future<_i3.DialogResponse<dynamic>?>.value(),
      ) as _i6.Future<_i3.DialogResponse<dynamic>?>);

  @override
  _i6.Future<_i3.DialogResponse<T>?> showCustomDialog<T, R>({
    dynamic variant,
    String? title,
    String? description,
    bool? hasImage = false,
    String? imageUrl,
    bool? showIconInMainButton = false,
    String? mainButtonTitle,
    bool? showIconInSecondaryButton = false,
    String? secondaryButtonTitle,
    bool? showIconInAdditionalButton = false,
    String? additionalButtonTitle,
    bool? takesInput = false,
    _i7.Color? barrierColor = const _i7.Color(2315255808),
    bool? barrierDismissible = false,
    String? barrierLabel = '',
    bool? useSafeArea = true,
    _i5.RouteSettings? routeSettings,
    _i5.GlobalKey<_i5.NavigatorState>? navigatorKey,
    _i5.RouteTransitionsBuilder? transitionBuilder,
    dynamic customData,
    R? data,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #showCustomDialog,
          [],
          {
            #variant: variant,
            #title: title,
            #description: description,
            #hasImage: hasImage,
            #imageUrl: imageUrl,
            #showIconInMainButton: showIconInMainButton,
            #mainButtonTitle: mainButtonTitle,
            #showIconInSecondaryButton: showIconInSecondaryButton,
            #secondaryButtonTitle: secondaryButtonTitle,
            #showIconInAdditionalButton: showIconInAdditionalButton,
            #additionalButtonTitle: additionalButtonTitle,
            #takesInput: takesInput,
            #barrierColor: barrierColor,
            #barrierDismissible: barrierDismissible,
            #barrierLabel: barrierLabel,
            #useSafeArea: useSafeArea,
            #routeSettings: routeSettings,
            #navigatorKey: navigatorKey,
            #transitionBuilder: transitionBuilder,
            #customData: customData,
            #data: data,
          },
        ),
        returnValue: _i6.Future<_i3.DialogResponse<T>?>.value(),
        returnValueForMissingStub: _i6.Future<_i3.DialogResponse<T>?>.value(),
      ) as _i6.Future<_i3.DialogResponse<T>?>);

  @override
  _i6.Future<_i3.DialogResponse<dynamic>?> showConfirmationDialog({
    String? title,
    String? description,
    String? cancelTitle = 'Cancel',
    _i7.Color? cancelTitleColor,
    String? confirmationTitle = 'Ok',
    _i7.Color? confirmationTitleColor,
    bool? barrierDismissible = false,
    _i5.RouteSettings? routeSettings,
    _i3.DialogPlatform? dialogPlatform,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #showConfirmationDialog,
          [],
          {
            #title: title,
            #description: description,
            #cancelTitle: cancelTitle,
            #cancelTitleColor: cancelTitleColor,
            #confirmationTitle: confirmationTitle,
            #confirmationTitleColor: confirmationTitleColor,
            #barrierDismissible: barrierDismissible,
            #routeSettings: routeSettings,
            #dialogPlatform: dialogPlatform,
          },
        ),
        returnValue: _i6.Future<_i3.DialogResponse<dynamic>?>.value(),
        returnValueForMissingStub:
            _i6.Future<_i3.DialogResponse<dynamic>?>.value(),
      ) as _i6.Future<_i3.DialogResponse<dynamic>?>);

  @override
  void completeDialog(_i3.DialogResponse<dynamic>? response) =>
      super.noSuchMethod(
        Invocation.method(
          #completeDialog,
          [response],
        ),
        returnValueForMissingStub: null,
      );
}

/// A class which mocks [AuthenticationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthenticationService extends _i1.Mock
    implements _i8.AuthenticationService {
  @override
  _i6.Stream<_i2.User?> observeAuthState() => (super.noSuchMethod(
        Invocation.method(
          #observeAuthState,
          [],
        ),
        returnValue: _i6.Stream<_i2.User?>.empty(),
        returnValueForMissingStub: _i6.Stream<_i2.User?>.empty(),
      ) as _i6.Stream<_i2.User?>);

  @override
  _i6.Future<_i2.UserCredential> signIn({
    required String? email,
    required String? password,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #signIn,
          [],
          {
            #email: email,
            #password: password,
          },
        ),
        returnValue: _i6.Future<_i2.UserCredential>.value(_FakeUserCredential_0(
          this,
          Invocation.method(
            #signIn,
            [],
            {
              #email: email,
              #password: password,
            },
          ),
        )),
        returnValueForMissingStub:
            _i6.Future<_i2.UserCredential>.value(_FakeUserCredential_0(
          this,
          Invocation.method(
            #signIn,
            [],
            {
              #email: email,
              #password: password,
            },
          ),
        )),
      ) as _i6.Future<_i2.UserCredential>);

  @override
  _i6.Future<_i2.UserCredential> signUp({
    required String? email,
    required String? password,
    required _i8.UserRole? userRole,
    String? name,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #signUp,
          [],
          {
            #email: email,
            #password: password,
            #userRole: userRole,
            #name: name,
          },
        ),
        returnValue: _i6.Future<_i2.UserCredential>.value(_FakeUserCredential_0(
          this,
          Invocation.method(
            #signUp,
            [],
            {
              #email: email,
              #password: password,
              #userRole: userRole,
              #name: name,
            },
          ),
        )),
        returnValueForMissingStub:
            _i6.Future<_i2.UserCredential>.value(_FakeUserCredential_0(
          this,
          Invocation.method(
            #signUp,
            [],
            {
              #email: email,
              #password: password,
              #userRole: userRole,
              #name: name,
            },
          ),
        )),
      ) as _i6.Future<_i2.UserCredential>);

  @override
  _i6.Future<void> sendPasswordReset({required String? email}) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendPasswordReset,
          [],
          {#email: email},
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  _i6.Future<void> signOut() => (super.noSuchMethod(
        Invocation.method(
          #signOut,
          [],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  _i6.Future<String?> fetchDisplayName() => (super.noSuchMethod(
        Invocation.method(
          #fetchDisplayName,
          [],
        ),
        returnValue: _i6.Future<String?>.value(),
        returnValueForMissingStub: _i6.Future<String?>.value(),
      ) as _i6.Future<String?>);

  @override
  _i6.Future<void> updateDisplayName(String? newName) => (super.noSuchMethod(
        Invocation.method(
          #updateDisplayName,
          [newName],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
}

/// A class which mocks [TestService].
///
/// See the documentation for Mockito's code generation for more information.
class MockTestService extends _i1.Mock implements _i9.TestService {
  @override
  _i6.Future<List<_i10.TestResult>> fetchResultsForPatient(String? patientId) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchResultsForPatient,
          [patientId],
        ),
        returnValue:
            _i6.Future<List<_i10.TestResult>>.value(<_i10.TestResult>[]),
        returnValueForMissingStub:
            _i6.Future<List<_i10.TestResult>>.value(<_i10.TestResult>[]),
      ) as _i6.Future<List<_i10.TestResult>>);

  @override
  _i6.Stream<List<_i10.TestResult>> watchResultsForPatient(String? patientId) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchResultsForPatient,
          [patientId],
        ),
        returnValue: _i6.Stream<List<_i10.TestResult>>.empty(),
        returnValueForMissingStub: _i6.Stream<List<_i10.TestResult>>.empty(),
      ) as _i6.Stream<List<_i10.TestResult>>);

  @override
  _i6.Future<void> addResult(_i10.TestResult? result) => (super.noSuchMethod(
        Invocation.method(
          #addResult,
          [result],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  Map<String, double> computeSummary(List<_i10.TestResult>? results) =>
      (super.noSuchMethod(
        Invocation.method(
          #computeSummary,
          [results],
        ),
        returnValue: <String, double>{},
        returnValueForMissingStub: <String, double>{},
      ) as Map<String, double>);
}

/// A class which mocks [ReportsService].
///
/// See the documentation for Mockito's code generation for more information.
class MockReportsService extends _i1.Mock implements _i11.ReportsService {
  @override
  _i6.Future<List<_i12.AppUser>> fetchAllDoctors() => (super.noSuchMethod(
        Invocation.method(
          #fetchAllDoctors,
          [],
        ),
        returnValue: _i6.Future<List<_i12.AppUser>>.value(<_i12.AppUser>[]),
        returnValueForMissingStub:
            _i6.Future<List<_i12.AppUser>>.value(<_i12.AppUser>[]),
      ) as _i6.Future<List<_i12.AppUser>>);

  @override
  _i6.Future<_i12.AppUser?> fetchUserById(String? uid) => (super.noSuchMethod(
        Invocation.method(
          #fetchUserById,
          [uid],
        ),
        returnValue: _i6.Future<_i12.AppUser?>.value(),
        returnValueForMissingStub: _i6.Future<_i12.AppUser?>.value(),
      ) as _i6.Future<_i12.AppUser?>);

  @override
  _i6.Future<void> sendResultsToDoctor({
    required String? patientId,
    required String? doctorId,
    required List<_i10.TestResult>? results,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendResultsToDoctor,
          [],
          {
            #patientId: patientId,
            #doctorId: doctorId,
            #results: results,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  _i6.Stream<List<_i13.PatientReport>> watchReportsForPatient(
          String? patientId) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchReportsForPatient,
          [patientId],
        ),
        returnValue: _i6.Stream<List<_i13.PatientReport>>.empty(),
        returnValueForMissingStub: _i6.Stream<List<_i13.PatientReport>>.empty(),
      ) as _i6.Stream<List<_i13.PatientReport>>);

  @override
  _i6.Stream<List<_i13.PatientReport>> watchReportsForDoctor(
          String? doctorId) =>
      (super.noSuchMethod(
        Invocation.method(
          #watchReportsForDoctor,
          [doctorId],
        ),
        returnValue: _i6.Stream<List<_i13.PatientReport>>.empty(),
        returnValueForMissingStub: _i6.Stream<List<_i13.PatientReport>>.empty(),
      ) as _i6.Stream<List<_i13.PatientReport>>);

  @override
  _i6.Future<void> addNoteToReport({
    required String? reportId,
    required _i14.DoctorNote? note,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #addNoteToReport,
          [],
          {
            #reportId: reportId,
            #note: note,
          },
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);
}
