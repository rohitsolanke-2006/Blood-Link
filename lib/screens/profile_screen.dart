// profile_screen.dart
// CHANGES:
// - Loads user data from Firestore (not SharedPreferences)
// - Availability toggle saves to Firestore
// - Logout uses AuthService
// - Edit dialog updates Firestore

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userBloodGroup = '';
  String userAge = '';
  String lastDonation = 'Never';
  int totalDonations = 0;
  bool isAvailable = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── LOAD PROFILE FROM FIRESTORE ────────────────────────────────
  Future<void> _loadProfile() async {
    final uid = AuthService.getCurrentUid();
    if (uid == null) return;

    // Fetch user profile from Firestore
    final data = await FirestoreService.getUserProfile(uid);

    if (!mounted) return;

    if (data != null) {
      setState(() {
        userName = data['name'] ?? 'User';
        userEmail = data['email'] ?? '';
        userPhone = data['phone'] ?? '';
        userBloodGroup = data['bloodGroup'] ?? 'N/A';
        userAge = data['age'] ?? '';
        isAvailable = data['isAvailable'] ?? true;
        totalDonations = data['totalDonations'] ?? 0;
        lastDonation = data['lastDonation'] ?? 'Never';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.white),
            onPressed: () {
              _showEditDialog(context);
            },
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── TOP RED SECTION ─────────────────────────
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  userBloodGroup.isEmpty
                                      ? 'N/A'
                                      : userBloodGroup,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          userEmail,
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _topStatBox('Total Donations', '$totalDonations'),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white.withOpacity(0.4),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            _topStatBox(
                              'Age',
                              userAge.isEmpty ? 'N/A' : '$userAge yrs',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── AVAILABILITY TOGGLE ──────────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.available
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Donation Availability',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                isAvailable
                                    ? 'You are available to donate'
                                    : 'You are not available to donate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Switch(
                          value: isAvailable,
                          onChanged: (bool newValue) async {
                            setState(() {
                              isAvailable = newValue;
                            });

                            // Save to Firestore (visible to all users)
                            final uid = AuthService.getCurrentUid();
                            if (uid != null) {
                              await FirestoreService.updateAvailability(
                                uid,
                                newValue,
                              );
                            }

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newValue
                                      ? 'You are now Available!'
                                      : 'You are now Unavailable',
                                ),
                                backgroundColor: newValue
                                    ? AppColors.available
                                    : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          activeThumbColor: AppColors.available,
                        ),
                      ],
                    ),
                  ),

                  // ── PERSONAL INFO ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _infoCard([
                          _infoRow(Icons.person_outline, 'Full Name', userName),
                          _divider(),
                          _infoRow(Icons.phone_outlined, 'Phone', userPhone),
                          _divider(),
                          _infoRow(Icons.email_outlined, 'Email', userEmail),
                          _divider(),
                          _infoRow(
                            Icons.bloodtype,
                            'Blood Group',
                            userBloodGroup,
                          ),
                          _divider(),
                          _infoRow(
                            Icons.cake_outlined,
                            'Age',
                            '$userAge years',
                          ),
                          _divider(),
                          _infoRow(
                            Icons.calendar_today_outlined,
                            'Last Donation',
                            lastDonation,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Donation History Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.history,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'View Donation History',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/donation-history');
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.white,
                            ),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              // Logout from Firebase Auth
                              await AuthService.logout();
                              if (!mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── HELPER WIDGETS (same UI as before) ─────────────────────────

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey[200], indent: 52);
  }

  Widget _topStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ── EDIT DIALOG ───────────────────────────────────────────────
  void _showEditDialog(BuildContext context) {
    final editNameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: editNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () async {
                final uid = AuthService.getCurrentUid();
                if (uid == null) return;

                // Update name in Firestore
                await FirestoreService.updateUserProfile(uid, {
                  'name': editNameController.text,
                });

                if (!mounted) return;

                setState(() {
                  userName = editNameController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated! ✅'),
                    backgroundColor: AppColors.available,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
