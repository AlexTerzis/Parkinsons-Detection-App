import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Success and warning colours, which Material 3's [ColorScheme] has no slot
/// for.
///
/// A [ThemeExtension] rather than plain constants so these resolve per-theme:
/// when a dark theme lands, `success` has to flip to a light tone, and the
/// ~50 call sites across the app keep working untouched.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.brandDark,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color brandDark;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppTokens.success,
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD3EDDF),
    onSuccessContainer: Color(0xFF08281A),
    // Dark, because AppTokens.warning is only 3.7:1 against white.
    warning: AppTokens.warning,
    onWarning: Color(0xFF241500),
    warningContainer: Color(0xFFFCEFD6),
    onWarningContainer: Color(0xFF4A300A),
    brandDark: AppTokens.primaryDark,
  );

  /// Resolves the extension, falling back to [light] rather than throwing.
  ///
  /// Always prefer this over `Theme.of(context).extension<AppSemanticColors>()!`,
  /// which blows up in any subtree built from a [ThemeData] that lacks the
  /// extension — a bare `Theme(data: ThemeData.light())` wrapper, a widget
  /// test, or a third-party widget supplying its own theme.
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? light;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? brandDark,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      brandDark: brandDark ?? this.brandDark,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
    );
  }
}
