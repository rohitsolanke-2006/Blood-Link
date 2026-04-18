// main.dart
// Entry point of the BloodLink app
//
// CHANGES:
// - Added Firebase.initializeApp() — MUST run before anything else
// - Added NotificationService.initialize() — sets up push notifications
// - Added navigatorKey for notification tap navigation
// - Added background message handler for FCM

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/create_request_screen.dart';
import 'screens/donation_history_screen.dart';
import 'screens/donor_detail_screen.dart';
import 'models/donor.dart';
import 'services/notification_service.dart';

// ── BACKGROUND MESSAGE HANDLER ───────────────────────────────────
// This function runs when a notification arrives and app is CLOSED
// It MUST be a top-level function (not inside a class)
// Firebase requires this to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (needed because this runs in a separate isolate)
  await Firebase.initializeApp();
  debugPrint('Background notification: ${message.notification?.title}');
}

void main() async {
  // ── STEP 1: Ensure Flutter is ready ────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();
  // Must be called before any async operations in main()

  // ── STEP 2: Initialize Firebase ────────────────────────────────
  // This connects your app to the Firebase project
  // It reads google-services.json to find your project
  // MUST be called before using any Firebase service
  await Firebase.initializeApp();

  // ── STEP 3: Register background message handler ────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Tells Firebase: "When a notification arrives and app is closed,
  // call this function"

  runApp(const BloodLinkApp());
}

class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodLink',
      debugShowCheckedModeBanner: false,

      // Use notification service's navigator key
      // This allows us to navigate when a notification is tapped
      navigatorKey: NotificationService.navigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // App starts at splash screen
      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/create-request': (context) => const CreateRequestScreen(),
        '/donation-history': (context) => const DonationHistoryScreen(),
      },

      // onGenerateRoute handles routes that need arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/donor-detail') {
          final donor = settings.arguments as Donor;
          return MaterialPageRoute(
            builder: (context) => DonorDetailScreen(donor: donor),
          );
        }
        return null;
      },
    );
  }
}
