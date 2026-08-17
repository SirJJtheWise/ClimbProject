import 'package:flutter/material.dart';

/// Crux Check design system.
///
/// Cream is the brand ground: in light mode every surface is a warm
/// off-white, and in dark mode cream becomes the foreground it is read
/// against, so the identity survives the theme flip instead of collapsing
/// into generic grey. Forest green is the accent — it carries primary
/// actions, hero numbers, and focus rings and nothing else, so "green"
/// consistently means "act on this" or "read this first".
///
/// Both schemes are written out by hand rather than generated from a seed:
/// `ColorScheme.fromSeed` derives surfaces from the seed hue, which cannot
/// produce a cream canvas next to a deep green accent — it would tint the
/// whole app green.
class AppTheme {
  AppTheme._();

  /// Brand ground.
  static const cream = Color(0xFFFAF6EC);

  /// Brand accent.
  static const forest = Color(0xFF1F5130);

  static const double cardRadius = 18;
  static const double controlRadius = 12;
  static const double pillRadius = 999;

  static ThemeData light() => _build(_lightScheme, _lightLevels);
  static ThemeData dark() => _build(_darkScheme, _darkLevels);

  // ---------------------------------------------------------------- schemes

  /// Cream canvas, forest accent. Bark (`secondary`) and stone
  /// (`tertiary`) exist mainly so the history charts can draw three series
  /// that stay distinguishable without leaning on the level scale's
  /// red/amber/green, which already means something else.
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: forest,
    onPrimary: Color(0xFFFBF8F0),
    primaryContainer: Color(0xFFD5E7D6),
    onPrimaryContainer: Color(0xFF0B2C18),
    secondary: Color(0xFF6A5836),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDE2C6),
    onSecondaryContainer: Color(0xFF241A05),
    tertiary: Color(0xFF3B5A6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD4E6F1),
    onTertiaryContainer: Color(0xFF0A1F2A),
    error: Color(0xFFA03024),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF7DAD3),
    onErrorContainer: Color(0xFF40100B),
    surface: cream,
    onSurface: Color(0xFF1C1B14),
    onSurfaceVariant: Color(0xFF55513F),
    surfaceDim: Color(0xFFE9E2CE),
    surfaceBright: Color(0xFFFFFDF7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F1E2),
    surfaceContainer: Color(0xFFF1EBD9),
    surfaceContainerHigh: Color(0xFFEBE4CE),
    surfaceContainerHighest: Color(0xFFE4DCC4),
    outline: Color(0xFF86816C),
    outlineVariant: Color(0xFFD8D1BA),
    shadow: Color(0xFF2A2617),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF31302A),
    onInverseSurface: Color(0xFFF4EFE0),
    inversePrimary: Color(0xFFA5D5AC),
    surfaceTint: forest,
  );

  /// Forest-tinted charcoal ground with cream as the reading colour. The
  /// accent inverts to a light sage so it still clears 4.5:1 on the dark
  /// surfaces — the deep forest green would be unreadable here.
  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA5D5AC),
    onPrimary: Color(0xFF0C361D),
    primaryContainer: Color(0xFF275A38),
    onPrimaryContainer: Color(0xFFC1EFC7),
    secondary: Color(0xFFDCC48D),
    onSecondary: Color(0xFF3C2F0C),
    secondaryContainer: Color(0xFF52441F),
    onSecondaryContainer: Color(0xFFF9E1A7),
    tertiary: Color(0xFFA3C9DC),
    onTertiary: Color(0xFF05323F),
    tertiaryContainer: Color(0xFF234956),
    onTertiaryContainer: Color(0xFFBFE5F9),
    error: Color(0xFFFFB4A6),
    onError: Color(0xFF5F1408),
    errorContainer: Color(0xFF7E2618),
    onErrorContainer: Color(0xFFFFDAD3),
    surface: Color(0xFF12160F),
    onSurface: Color(0xFFEFE9D8),
    onSurfaceVariant: Color(0xFFC6C0AA),
    surfaceDim: Color(0xFF12160F),
    surfaceBright: Color(0xFF383E33),
    surfaceContainerLowest: Color(0xFF0C0F0A),
    surfaceContainerLow: Color(0xFF1A1F16),
    surfaceContainer: Color(0xFF1E2419),
    surfaceContainerHigh: Color(0xFF282F22),
    surfaceContainerHighest: Color(0xFF333A2C),
    outline: Color(0xFF8F8A76),
    outlineVariant: Color(0xFF454B3D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEFE9D8),
    onInverseSurface: Color(0xFF2F2E28),
    inversePrimary: forest,
    surfaceTint: Color(0xFFA5D5AC),
  );

  // ----------------------------------------------------------- level scale

  /// Weakness/at-level/strength shades, tuned per brightness for >=4.5:1
  /// against that theme's card surfaces. Kept off the brand green on the
  /// "strong" end only far enough to stay distinguishable — green still
  /// reads as good, which is the point.
  static const _lightLevels = LevelPalette(
    weak: Color(0xFFA8342A),
    weakSurface: Color(0xFFF6DBD6),
    atLevel: Color(0xFF8F6110),
    atLevelSurface: Color(0xFFF6E7C8),
    strong: Color(0xFF2A6B3C),
    strongSurface: Color(0xFFD8EBDC),
  );

  static const _darkLevels = LevelPalette(
    weak: Color(0xFFFF9E90),
    weakSurface: Color(0xFF4A1810),
    atLevel: Color(0xFFE5C158),
    atLevelSurface: Color(0xFF423308),
    strong: Color(0xFF8FD79C),
    strongSurface: Color(0xFF1B3F27),
  );

  // ----------------------------------------------------------------- build

  static ThemeData _build(ColorScheme colorScheme, LevelPalette levels) {
    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, colorScheme);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return base.copyWith(
      extensions: [levels],
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // InkRipple rather than InkSparkle: the sparkle shader degrades on
      // web, which this app builds for, and a press response that differs
      // per platform is worse than a plain one that never does.
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
        ),
      ),
      // Cream cards on a cream canvas need an edge, not a shadow — a
      // hairline outline separates them at any elevation and survives the
      // dark theme, where a drop shadow would be invisible.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      // Finite minWidth (not Size.fromHeight's infinite width) so a lone
      // button in a full-width ListView/Column still gets a tall, easy tap
      // target, but two buttons side by side in a Row (HangTimer's
      // Start/Stop + Reset) don't each demand the whole row.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 48),
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 44),
          foregroundColor: colorScheme.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(64, 48),
          selectedBackgroundColor: colorScheme.primaryContainer,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color:
                selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: AppSpacing.xxl,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? colorScheme.onPrimary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? colorScheme.primary : null),
      ),
    );
  }

  /// Bold, tabular-figure numerals on every "hero number" role — grade
  /// estimates, timers, %BW — so digits don't jitter sideways as they
  /// change and the scale reads as an intentional step, not default M3.
  /// Negative tracking on the large sizes is what keeps big numerals from
  /// looking loose and default at display sizes.
  static TextTheme _textTheme(TextTheme base, ColorScheme colorScheme) {
    const tabular = [FontFeature.tabularFigures()];
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              fontFeatures: tabular),
          displayMedium: base.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontFeatures: tabular),
          displaySmall: base.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontFeatures: tabular),
          headlineMedium: base.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              fontFeatures: tabular),
          headlineSmall: base.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: tabular),
          titleLarge: base.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
          bodySmall: base.bodySmall?.copyWith(height: 1.4),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          labelSmall: base.labelSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
  }
}

/// The app's 4dp-based spacing rhythm. Three section tiers ([lg], [xl],
/// [xxl]) so vertical gaps communicate grouping depth instead of being
/// re-guessed on every screen, plus a single [gutter] that keeps content
/// width identical across screens.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal page inset.
  static const double gutter = 20;

  /// Bottom padding for scroll views that sit under the navigation bar, so
  /// the last card is never trapped behind it.
  static const double scrollBottomInset = 32;
}

/// The single weakness / at-level / strength colour scale, resolved per
/// theme. Lives as a [ThemeExtension] so widgets read it through
/// `Theme.of(context)` like any other token, instead of hardcoding
/// `Colors.red.shade700` that only works in light mode.
@immutable
class LevelPalette extends ThemeExtension<LevelPalette> {
  final Color weak;
  final Color weakSurface;
  final Color atLevel;
  final Color atLevelSurface;
  final Color strong;
  final Color strongSurface;

  const LevelPalette({
    required this.weak,
    required this.weakSurface,
    required this.atLevel,
    required this.atLevelSurface,
    required this.strong,
    required this.strongSurface,
  });

  @override
  LevelPalette copyWith({
    Color? weak,
    Color? weakSurface,
    Color? atLevel,
    Color? atLevelSurface,
    Color? strong,
    Color? strongSurface,
  }) {
    return LevelPalette(
      weak: weak ?? this.weak,
      weakSurface: weakSurface ?? this.weakSurface,
      atLevel: atLevel ?? this.atLevel,
      atLevelSurface: atLevelSurface ?? this.atLevelSurface,
      strong: strong ?? this.strong,
      strongSurface: strongSurface ?? this.strongSurface,
    );
  }

  @override
  LevelPalette lerp(ThemeExtension<LevelPalette>? other, double t) {
    if (other is! LevelPalette) return this;
    return LevelPalette(
      weak: Color.lerp(weak, other.weak, t)!,
      weakSurface: Color.lerp(weakSurface, other.weakSurface, t)!,
      atLevel: Color.lerp(atLevel, other.atLevel, t)!,
      atLevelSurface: Color.lerp(atLevelSurface, other.atLevelSurface, t)!,
      strong: Color.lerp(strong, other.strong, t)!,
      strongSurface: Color.lerp(strongSurface, other.strongSurface, t)!,
    );
  }
}
