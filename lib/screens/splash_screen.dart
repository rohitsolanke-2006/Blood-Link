// splash_screen.dart
// First screen that appears when app opens
// Shows BloodLink logo for 2 seconds
// Then checks Firebase Auth to decide: Login or Home
//
// CHANGES:
// - Replaced StorageHelper.isLoggedIn() with AuthService.isLoggedIn()
// - Added NotificationService.initialize() after login check

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  // ── NAVIGATE AFTER 2 SECONDS ──────────────────────────────────
  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in using Firebase Auth
    // Firebase remembers the session even after app restart!
    final bool loggedIn = AuthService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // User is logged in → initialize notifications then go to main
      // We initialize notifications here because we need the user's uid
      // to save the FCM token
      await NotificationService.initialize();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bloodtype,
                size: 80,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BloodLink',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Emergency Blood Donor Network',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.85),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.white.withOpacity(0.7),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}