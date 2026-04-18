// donor_detail_screen.dart
// Shows full information about a single donor
// Opened when user taps "View Profile" on donor list
// Receives a Donor object passed from donor_list_screen

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/donor.dart';
import '../utils/call_helper.dart';
class DonorDetailScreen extends StatelessWidget {
  // This screen receives a donor object from previous screen
  final Donor donor;
  // final = this donor data won't change on this screen

  const DonorDetailScreen({
    super.key,
    required this.donor,
    // required = donor MUST be passed when opening this screen
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Donor Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // ── TOP RED SECTION ───────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Avatar Circle
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: Text(
                          donor.firstLetter,
                          // Uses getter from Donor model
                          style: const TextStyle(
                            fontSize: 40,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Blood group badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            donor.bloodGroup,
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

                  // Donor Name
                  Text(
                    donor.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Availability Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: donor.isAvailable
                          ? AppColors.available
                          : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donor.isAvailable
                          ? '● Available to Donate'
                          : '● Not Available',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBox('Total\nDonations',
                          '${donor.totalDonations}'),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withOpacity(0.4),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      _statBox('Last\nDonation', donor.lastDonation),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withOpacity(0.4),
                        margin:
                        const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      _statBox('Distance', donor.location),
                    ],
                  ),
                ],
              ),
            ),

            // ── PERSONAL DETAILS CARD ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.person_outline,
                            'Full Name', donor.name),
                        _divider(),
                        _infoRow(Icons.cake_outlined,
                            'Age', '${donor.age} years'),
                        _divider(),
                        _infoRow(Icons.people_outline,
                            'Gender', donor.gender),
                        _divider(),
                        _infoRow(Icons.bloodtype,
                            'Blood Group', donor.bloodGroup),
                        _divider(),
                        _infoRow(Icons.phone_outlined,
                            'Phone', donor.phone),
                        _divider(),
                        _infoRow(Icons.email_outlined,
                            'Email', donor.email),
                        _divider(),
                        _infoRow(Icons.location_on_outlined,
                            'Location', donor.location),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── ACTION BUTTONS ────────────────────────────
                  // Call Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone,
                          color: AppColors.white),
                      label: Text(
                        donor.isAvailable
                            ? 'Call ${donor.name}'
                            : 'Donor Not Available',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: donor.isAvailable
                            ? AppColors.primary
                            : Colors.grey,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: donor.isAvailable
                          ? () {
                        CallHelper.makeCall(context, donor.phone);
                      }
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primary),
                      label: const Text(
                        'Back to Donor List',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // pop = go back to donor list
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPER: _statBox ──────────────────────────────────────────────
  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── HELPER: _infoRow ──────────────────────────────────────────────
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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

  // ── HELPER: _divider ──────────────────────────────────────────────
  Widget _divider() {
    return Divider(height: 1, color: Colors.grey[200], indent: 52);
  }
}