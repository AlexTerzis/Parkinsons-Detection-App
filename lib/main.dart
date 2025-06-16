import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.bottomsheets.dart';
import 'package:parkinsondetetion/app/app.dialogs.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/app/app.router.dart';
import 'package:parkinsondetetion/firebase_options.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked_services/stacked_services.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  // runApp(const MyApp());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveApp(
      builder: (_) => MaterialApp(
        title: "Parkinson's Detection",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        // Use the Stacked router for navigation
        initialRoute: Routes.startupView,
        onGenerateRoute: StackedRouter().onGenerateRoute,
        navigatorKey: StackedService.navigatorKey,
      ),
    );
  }
}
