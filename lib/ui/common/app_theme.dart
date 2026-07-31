import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'app_tokens.dart';

/// The app's Material 3 theme.
///
/// Component themes here do most of the accessibility work: they lift roughly
/// 160 of the app's ~190 interactive elements to the [AppSize.minTap] target
/// without any per-screen edits, including on screens this migration never
/// touched by hand.
abstract final class AppTheme {
  /// Builds the light theme.
  ///
  /// [tabBarTextScaler] is applied to tab labels only. Flutter's
  /// `_kTextAndIconTabHeight` is a compile-time constant that does not grow
  /// with the text scaler, and both tab bars in this app run with
  /// `toolbarHeight: 0` (the tab bar *is* the app bar), so unbounded label
  /// scaling overflows visibly. Callers pass a clamped scaler.
  static ThemeData light({
    TextScaler tabBarTextScaler = TextScaler.noScaling,
  }) {
    const cs = _lightScheme;
    final text = _textTheme(cs);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    );
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: text,
      extensions: const <ThemeExtension<dynamic>>[AppSemanticColors.light],

      scaffoldBackgroundColor: AppTokens.pageBackground,
      canvasColor: cs.surface,

      // `padded` gives a 48 floor to widgets with no size knob of their own
      // (Checkbox, Radio, Switch, Chip). `standard` density rather than
      // adaptivePlatformDensity, which *compresses* on desktop and web — the
      // opposite of what this audience needs.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      iconTheme: const IconThemeData(
        color: AppTokens.onSurfaceMuted,
        size: 24,
      ),

      // --- Buttons: the minimum-tap-target rule ---------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, AppSize.minTap),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSize.minTap),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSize.minTap),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, AppSize.minTap),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: cs.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSize.minTap, AppSize.minTap),
          iconSize: AppSize.iconMd,
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: cs.primary,
        ),
      ),

      // --- App bar ---------------------------------------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: cs.onSurface),
        iconTheme: IconThemeData(color: cs.primary, size: AppSize.iconMd),
        actionsIconTheme:
            IconThemeData(color: cs.primary, size: AppSize.iconMd),
        // Stands in for the "scrolled under" tint disabled via surfaceTint.
        shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),

      // --- Cards: outlined rather than elevated ----------------------------
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      // --- Inputs ----------------------------------------------------------
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppTokens.pageBackground,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 18,
        ),
        labelStyle: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: cs.primary),
        hintStyle: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: cs.error),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        // Without these the mic buttons used as suffixIcon stay squeezed by
        // the decorator, whatever iconButtonTheme says.
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSize.minTap,
          minHeight: AppSize.minTap,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppSize.minTap,
          minHeight: AppSize.minTap,
        ),
        border: inputBorder(cs.outline),
        enabledBorder: inputBorder(cs.outline),
        focusedBorder: inputBorder(cs.primary, 2),
        errorBorder: inputBorder(cs.error, 1.5),
        focusedErrorBorder: inputBorder(cs.error, 2),
      ),

      // --- Chips -----------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.secondaryContainer,
        checkmarkColor: cs.onSecondaryContainer,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        showCheckmark: true,
      ),

      // --- Slider: oversized thumb, for tremor -----------------------------
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 16,
          pressedElevation: 6,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
        valueIndicatorShape: const DropSliderValueIndicatorShape(),
        showValueIndicator: ShowValueIndicator.onDrag,
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.surfaceContainerHighest,
        thumbColor: cs.primary,
        overlayColor: cs.primary.withValues(alpha: 0.12),
        valueIndicatorColor: cs.inverseSurface,
        valueIndicatorTextStyle:
            text.labelLarge?.copyWith(color: cs.onInverseSurface),
      ),

      // --- Tabs -------------------------------------------------------------
      // tabAlignment is deliberately not set here: TabBar asserts when
      // TabAlignment.start meets isScrollable: false, so a theme-wide value
      // would crash any future non-scrollable tab bar. Set it per call site.
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        textScaler: tabBarTextScaler,
      ),

      // --- List tiles: the app's primary navigation -------------------------
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        iconColor: cs.primary,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle:
            text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // --- Selection controls (framework caps these at 48) ------------------
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        side: BorderSide(width: 2, color: cs.outline),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? cs.primary
              : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? cs.primary : cs.outline,
        ),
      ),
      switchTheme: const SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // --- Overlays ---------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        titleTextStyle: text.headlineSmall?.copyWith(color: cs.onSurface),
        contentTextStyle: text.bodyLarge?.copyWith(color: cs.onSurface),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTokens.primaryDark,
        contentTextStyle: text.bodyLarge?.copyWith(color: AppTokens.surface),
        actionTextColor: cs.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHighest,
        circularTrackColor: cs.surfaceContainerHighest,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: cs.primary,
        collapsedIconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        collapsedTextColor: cs.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// Built explicitly rather than via [ColorScheme.fromSeed].
///
/// `fromSeed` runs Material's HCT tonal derivation, which offers no guarantee
/// that the seed colour appears anywhere in the result — the chosen brand
/// hexes would simply be lost. Seeding and then `copyWith`-ing the main roles
/// is worse: containers, `inversePrimary` and `surfaceTint` stay derived from
/// the seed at a different chroma, so cards and dialogs end up carrying a
/// subtly different teal than the buttons.
const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,

  primary: AppTokens.primary,
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFC9E7E3),
  onPrimaryContainer: Color(0xFF00201D),

  secondary: AppTokens.secondary,
  // Dark rather than white: AppTokens.secondary is only 3.3:1 against white.
  onSecondary: Color(0xFF06322D),
  secondaryContainer: Color(0xFFD6EBE8),
  onSecondaryContainer: Color(0xFF0B2E2A),

  tertiary: AppTokens.accent,
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFD3E4F7),
  onTertiaryContainer: Color(0xFF06203C),

  error: AppTokens.error,
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),

  surface: AppTokens.surface,
  onSurface: AppTokens.onSurface,
  onSurfaceVariant: AppTokens.onSurfaceMuted,

  surfaceDim: Color(0xFFDDE5E3),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: AppTokens.pageBackground,
  surfaceContainer: AppTokens.surfaceMuted,
  surfaceContainerHigh: Color(0xFFE8F0EE),
  surfaceContainerHighest: Color(0xFFE1EAE8),

  outline: AppTokens.outline,
  outlineVariant: AppTokens.outlineVariant,

  inverseSurface: Color(0xFF12211F),
  onInverseSurface: Color(0xFFEFF6F4),
  inversePrimary: Color(0xFF7FD3C9),

  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),

  // Material 3 tints every elevated surface with surfaceTint, which reads as a
  // dirty wash over a clinical white UI. Separation comes from outline borders
  // and the app bar's bottom border instead.
  surfaceTint: Color(0x00000000),
);

/// Maps the twenty-two ad-hoc font sizes the app had accumulated onto the
/// Material 3 type roles.
///
/// Body and label roles sit one step above the Material defaults (bodyLarge 17
/// rather than 16, labelLarge 15 rather than 14): the audience skews older, and
/// this also gives the text-scale feature a better starting point.
TextTheme _textTheme(ColorScheme cs) {
  final base = Typography.material2021(colorScheme: cs).black;
  return base
      .copyWith(
        // 64 rather than the Material 57 so the large numeric readouts in the
        // test steps (previously 72) do not visibly shrink.
        displayLarge: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            height: 1.05,
            letterSpacing: -0.5),
        displayMedium: const TextStyle(
            fontSize: 45, fontWeight: FontWeight.w400, height: 1.10),
        displaySmall: const TextStyle(
            fontSize: 36, fontWeight: FontWeight.w400, height: 1.15),
        headlineLarge: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w600, height: 1.20),
        headlineMedium: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w600, height: 1.22),
        headlineSmall: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
        titleLarge: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, height: 1.28),
        titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.33,
            letterSpacing: 0.10),
        titleSmall: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.40,
            letterSpacing: 0.10),
        bodyLarge: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.15),
        bodyMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.20),
        bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.40,
            letterSpacing: 0.25),
        labelLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.30,
            letterSpacing: 0.10),
        labelMedium: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.30,
            letterSpacing: 0.40),
        labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.30,
            letterSpacing: 0.40),
      )
      .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
}
