import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.bottomsheets.dart';
import 'package:parkinsondetetion/app/app.dialogs.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/services/localization_service.dart';
import 'package:parkinsondetetion/services/text_scale_service.dart';
import 'package:parkinsondetetion/ui/common/app_theme.dart';
import 'package:parkinsondetetion/ui/common/app_tokens.dart';
import 'package:parkinsondetetion/app/app.router.dart';
import 'package:parkinsondetetion/firebase_options.dart';
import 'package:parkinsondetetion/ui/views/login/login_view.dart';
import 'package:parkinsondetetion/ui/views/patience/patience_view.dart';
import 'package:parkinsondetetion/ui/views/doctor/doctor_view.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator();
  // Load persisted locale before the UI starts so the correct language
  // renders immediately. The service notifies listeners on changes.
  await locator<LocalizationService>().init();
  // Load the saved text size before the first frame, otherwise the whole app
  // visibly reflows a frame after launch.
  await locator<TextScaleService>().init();
  setupDialogUi();
  setupBottomSheetUi();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain the services holding the current locale and text size.
    final localizationService = locator<LocalizationService>();
    final textScaleService = locator<TextScaleService>();

    // Rebuilds MaterialApp whenever the locale or the text size changes. Both
    // invalidate the same subtree, so one merged listenable beats nesting two
    // builders.
    return AnimatedBuilder(
      animation: Listenable.merge([localizationService, textScaleService]),
      builder: (context, _) => ResponsiveApp(
        builder: (_) => MaterialApp(
          // onGenerateTitle uses the localized string at runtime.
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)!.appTitle,
          locale: localizationService.locale,
          supportedLocales: const [Locale('en'), Locale('el')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(
            tabBarTextScaler: textScaleService.tabBarTextScaler,
          ),

          // Deliberately in MaterialApp.builder rather than above MaterialApp.
          // MediaQuery.of depends on the whole MediaQueryData, so an override
          // higher up would rebuild the entire Navigator every time the
          // keyboard animates open or closed - which this app does constantly,
          // between the login form, both profile tabs and the speech-driven
          // test steps. Down here, element reuse keeps the route subtree
          // untouched. It also covers dialogs and sheets pushed through the
          // stacked navigator key.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: textScaleService.textScaler),
            child: child!,
          ),

          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          onGenerateRoute: StackedRouter().onGenerateRoute,
          navigatorKey: StackedService.navigatorKey,
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentDot = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startSplashLogic();
  }

  void _startSplashLogic() {
    // Start the dot animation
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        _currentDot = (_currentDot + 1) % 3;
      });
    });

    // Start login logic in parallel
    _checkLoginAndNavigate();
  }

  /// Just long enough that a fast launch reads as a brief brand moment rather
  /// than a flicker. The splash is not padded beyond this — it lasts as long as
  /// the work below actually takes, and no longer.
  static const Duration _minimumSplash = Duration(milliseconds: 350);

  /// Cap on the role lookup. Firestore will wait a long time on a bad
  /// connection, and nothing here is worth blocking the launch for: the cached
  /// role covers the offline case.
  static const Duration _roleLookupTimeout = Duration(seconds: 4);

  static const String _cachedRoleKey = 'cachedRole';

  Future<void> _checkLoginAndNavigate() async {
    // Run the work and the minimum splash concurrently, so the floor overlaps
    // the launch instead of being added to it.
    final results = await Future.wait(<Future<dynamic>>[
      _resolveTarget(),
      Future<void>.delayed(_minimumSplash),
    ]);
    final target = results.first as Widget;

    if (!mounted) return;

    _timer.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Decides where to land: login, patient home, or doctor home.
  Future<Widget> _resolveTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final keepMeLoggedIn = prefs.getBool('keepMeLoggedIn') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!keepMeLoggedIn || user == null) return LoginView();

    // Signed in already, so the only open question is which home to show.
    // Falling back to the login screen here would be wrong: it would ask a
    // signed-in user to sign in again just because the network was slow.
    String role = prefs.getString(_cachedRoleKey) ?? 'patient';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(_roleLookupTimeout);

      final fetched = userDoc.data()?['role'] as String?;
      if (fetched != null) {
        role = fetched;
        // Cached so the next launch can route correctly while offline, and
        // without waiting on the network at all.
        await prefs.setString(_cachedRoleKey, fetched);
      }
    } catch (e) {
      debugPrint('Role lookup failed, using cached role "$role": $e');
    }

    return role == 'doctor' ? const DoctorView() : const PatienceView();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedOpacity(
      opacity: _currentDot == index ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 300),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        // Brand accent that reads against the dark splash background.
        child: CircleAvatar(radius: 5, backgroundColor: Color(0xFF7FD3C9)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches flutter_native_splash's configured colour in pubspec.yaml, so
      // there is no flash between the native splash and this screen.
      backgroundColor: AppTokens.splashBackground,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/loading_screen.png',
              fit: BoxFit.fill,
            ),
          ),

          // Dots animation
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, _buildDot),
            ),
          ),
        ],
      ),
    );
  }
}
