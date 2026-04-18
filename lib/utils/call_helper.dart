// call_helper.dart
// This file handles phone call functionality
// url_launcher package opens the phone dialer
// with the number pre-filled

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class CallHelper {

  // ── MAKE CALL ─────────────────────────────────────────────────────
  // Opens phone dialer with given number
  // static = call as CallHelper.makeCall() directly
  static Future<void> makeCall(
      BuildContext context, String phoneNumber) async {

    // Clean the phone number
    // Remove spaces, dashes, brackets if any
    // e.g. "987-654-3210" → "9876543210"
    String cleanNumber = phoneNumber.replaceAll(
        RegExp(r'[\s\-\(\)]'), '');
    // RegExp = Regular Expression
    // r'[\s\-\(\)]' = matches spaces, dashes, brackets
    // .replaceAll() = removes all matches

    // Create the phone URI
    // tel: is the scheme that tells device to open dialer
    // e.g. tel:9876543210
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    // Check if device can open this URI
    // canLaunchUrl = returns true if device has a phone app
    if (await canLaunchUrl(phoneUri)) {
      // Open the phone dialer
      await launchUrl(phoneUri);
    } else {
      // Device cannot make calls → show error
      // This happens on emulator (no phone app)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot make call to $phoneNumber\n'
                  'This feature works on real devices only',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}