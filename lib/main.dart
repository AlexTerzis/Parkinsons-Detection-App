import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.bottomsheets.dart';
import 'package:parkinsondetetion/app/app.dialogs.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/services/localization_service.dart';
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
  setupDialogUi();
  setupBottomSheetUi();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain the localization service which holds the current locale.
    final localizationService = locator<LocalizationService>();

    // AnimatedBuilder rebuilds MaterialApp whenever the locale changes.
    return AnimatedBuilder(
      animation: localizationService,
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
          theme: AppTheme.light(),
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

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final keepMeLoggedIn = prefs.getBool('keepMeLoggedIn') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    Widget target = LoginView();

    if (keepMeLoggedIn && user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = userDoc.data()?['role'] ?? 'patient';

        if (role == 'doctor') {
          target = const DoctorView();
        } else {
          target = const PatienceView();
        }
      } catch (_) {
        // Default fallback remains LoginView
      }
    }

    // Wait exactly 3 seconds total (including checks)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    _timer.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
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
