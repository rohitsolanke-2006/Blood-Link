// main_screen.dart
// This screen holds the Bottom Navigation Bar
// It shows 4 tabs:
// Home | Requests | Donors | Profile
// Switching tabs shows different screens

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'home_screen.dart';
import 'request_feed_screen.dart';
import 'donor_list_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Currently selected tab index
  // 0 = Home, 1 = Requests, 2 = Donors, 3 = Profile
  int _currentIndex = 0;

  // List of all screens
  // Index matches the tab index above
  final List<Widget> _screens = [
    const HomeScreen(),
    const RequestFeedScreen(),
    const DonorListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shows the screen at current index
      body: _screens[_currentIndex],
      // _screens[0] = HomeScreen
      // _screens[1] = RequestFeedScreen
      // etc.

      // ── BOTTOM NAVIGATION BAR ───────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        // currentIndex = which tab is highlighted
        onTap: (int index) {
          // Runs when user taps a tab
          setState(() {
            _currentIndex = index;
            // Update current index → rebuilds screen
          });
        },

        type: BottomNavigationBarType.fixed,

        // fixed = all tabs always visible
        // (default shifts tabs when more than 3)
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        // selectedItemColor = color of active tab
        unselectedItemColor: Colors.grey,
        // unselectedItemColor = color of inactive tabs
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        // elevation = shadow above the nav bar

        // ── TAB ITEMS ─────────────────────────────────────────────
        items: const [
          // Tab 0 — Home
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            // activeIcon = icon when this tab is selected
            label: 'Home',
          ),

          // Tab 1 — Requests
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Requests',
          ),

          // Tab 2 — Donors
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Donors',
          ),

          // Tab 3 — Profile
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
