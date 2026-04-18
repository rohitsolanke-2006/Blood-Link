// notification_service.dart
// Handles push notifications using Firebase Cloud Messaging (FCM)
//
// WHAT IS FCM (Firebase Cloud Messaging)?
// It's like a postal service for apps:
// 1. Each phone gets a unique "address" called FCM Token
// 2. When someone creates a blood request, we look up matching donors
// 3. We send a "letter" (notification) to their FCM Token
// 4. The phone shows a notification banner — even if app is closed!
//
// HOW NOTIFICATIONS WORK IN FLUTTER:
// - FOREGROUND: App is open → we use flutter_local_notifications to show banner
// - BACKGROUND: App is minimized → FCM automatically shows notification
// - TERMINATED: App is closed → FCM still delivers notification!

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

class NotificationService {

  // ── INSTANCES ──────────────────────────────────────────────────
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Global navigator key — used to navigate when notification is tapped
  // We need this because notification tap happens outside any screen
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── INITIALIZE ─────────────────────────────────────────────────
  // Called once when app starts (in main.dart)
  // Sets up everything needed for notifications
  static Future<void> initialize() async {

    // ── STEP 1: Request permission ───────────────────────────────
    // On Android 13+, we need to ask user for notification permission
    // On older Android, permission is granted by default
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,     // Show notification banner
      badge: true,     // Show red dot on app icon
      sound: true,     // Play notification sound
    );
    // User can deny — we just won't send notifications then
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // ── STEP 2: Get FCM Token ────────────────────────────────────
    // This is the unique "address" for this phone
    // We save it in Firestore so we can send notifications to it later
    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Save token to Firestore under current user
    if (token != null) {
      final uid = AuthService.getCurrentUid();
      if (uid != null) {
        await FirestoreService.saveFcmToken(uid, token);
      }
    }

    // ── STEP 3: Listen for token refresh ─────────────────────────
    // FCM token can change (e.g., app reinstall, phone reset)
    // We listen for changes and update Firestore
    _fcm.onTokenRefresh.listen((newToken) async {
      final uid = AuthService.getCurrentUid();
      if (uid != null) {
        await FirestoreService.saveFcmToken(uid, newToken);
      }
    });

    // ── STEP 4: Setup local notifications (for foreground) ───────
    // flutter_local_notifications handles showing banners when app is open
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // @mipmap/ic_launcher = uses app icon as notification icon

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // This runs when user TAPS a foreground notification
        _handleNotificationTap(response.payload);
      },
    );

    // ── STEP 5: Create notification channel (Android 8+) ─────────
    // Android requires a "channel" for notifications
    // Channel defines sound, vibration, importance etc.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'blood_requests',        // Channel ID
      'Blood Requests',        // Channel name (shown in Settings)
      description: 'Notifications for urgent blood requests',
      importance: Importance.high,
      // high = shows as heads-up notification (banner at top)
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ── STEP 6: Handle foreground messages ───────────────────────
    // When app is OPEN and a notification arrives
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // ── STEP 7: Handle notification tap (app in background) ──────
    // When user taps notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['requestId']);
    });

    // ── STEP 8: Handle notification tap (app was terminated) ─────
    // If app was completely closed and user tapped notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['requestId']);
    }
  }

  // ── SHOW LOCAL NOTIFICATION ────────────────────────────────────
  // Shows a notification banner when app is in foreground
  // Uses flutter_local_notifications package
  static void _showLocalNotification(RemoteMessage message) {
    // Extract title and body from the notification
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      // hashCode = unique number for this notification
      notification.title ?? 'BloodLink',
      notification.body ?? 'You have a new notification',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'blood_requests',        // Must match channel ID above
          'Blood Requests',        // Channel name
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          // high priority = shows as heads-up banner
          color: Color(0xFFD32F2F),
          // Red color for notification icon tint
        ),
      ),
      payload: message.data['requestId'],
      // payload = extra data attached to notification
      // When user taps, we get this back to know which request to open
    );
  }

  // ── HANDLE NOTIFICATION TAP ────────────────────────────────────
  // When user taps a notification, navigate to the specific request
  static void _handleNotificationTap(String? requestId) {
    if (requestId != null) {
      // Navigate to main screen (request feed tab)
      // Using the global navigator key
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/main',
        (route) => false,
      );
      // For simplicity, we navigate to main screen
      // which shows the request feed tab
      // The user can then find the specific request
    }
  }

  // ── UPDATE TOKEN ON LOGIN ──────────────────────────────────────
  // Called after login to make sure the token is saved for this user
  static Future<void> updateTokenOnLogin() async {
    String? token = await _fcm.getToken();
    final uid = AuthService.getCurrentUid();
    if (token != null && uid != null) {
      await FirestoreService.saveFcmToken(uid, token);
    }
  }
}
