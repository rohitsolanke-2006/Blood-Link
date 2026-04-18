// donor_list_screen.dart
// CHANGES:
// - Replaced Donor.sampleData() with FirestoreService.getAllDonors() Stream
// - Uses StreamBuilder for real-time updates
// - Donors are now REAL registered users from Firestore!
// - Availability toggle saves to Firestore (visible to all users)
// - Kept all search, filter, and card UI exactly same

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/donor.dart';
import 'donor_detail_screen.dart';
import '../utils/call_helper.dart';
import '../services/firestore_service.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  // Search and filter state — same as before
  String searchQuery = '';
  String? selectedBloodGroup;
  bool showAvailableOnly = false;
  final TextEditingController searchController = TextEditingController();

  final List<String> bloodGroupFilters = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  // ── APPLY FILTERS ─────────────────────────────────────────────
  List<Donor> _applyFilters(List<Donor> allDonors) {
    List<Donor> result = allDonors;

    if (searchQuery.isNotEmpty) {
      result = result.where((donor) {
        return donor.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            donor.bloodGroup.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            donor.location.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectedBloodGroup != null) {
      result = result.where((donor) {
        return donor.bloodGroup == selectedBloodGroup;
      }).toList();
    }

    if (showAvailableOnly) {
      result = result.where((donor) {
        return donor.isAvailable == true;
      }).toList();
    }

    return result;
  }

  // ── TOGGLE AVAILABILITY ───────────────────────────────────────
  // Now saves to Firestore — visible to ALL users!
  void _toggleAvailability(Donor donor) async {
    final newStatus = !donor.isAvailable;
    await FirestoreService.updateAvailability(donor.id, newStatus);
    // StreamBuilder auto-updates — no setState needed!

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? '${donor.name} is now Available ✅'
              : '${donor.name} is now Unavailable ❌',
        ),
        backgroundColor: newStatus ? AppColors.available : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Find Donors',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      // ── STREAMBUILDER ─────────────────────────────────────────
      // Listens to real-time changes in the users collection
      body: StreamBuilder<List<Donor>>(
        stream: FirestoreService.getAllDonors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDonors = snapshot.data ?? [];
          final filteredDonors = _applyFilters(allDonors);
          int availableCount = allDonors.where((d) => d.isAvailable).length;

          return Column(
            children: [
              // ── AppBar count badge (shown as part of body) ──
              // We moved this to a banner since AppBar can't use
              // StreamBuilder data directly with this pattern
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$availableCount Available',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── SEARCH + FILTER SECTION ───────────────────
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name, blood group, location...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: bloodGroupFilters.map((group) {
                          bool isSelected = group == 'All'
                              ? selectedBloodGroup == null
                              : selectedBloodGroup == group;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                group,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedBloodGroup = group == 'All'
                                      ? null
                                      : group;
                                });
                              },
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.primary,
                              checkmarkColor: AppColors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.available,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Show Available Only',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: showAvailableOnly,
                          onChanged: (value) {
                            setState(() {
                              showAvailableOnly = value;
                            });
                          },
                          activeThumbColor: AppColors.available,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── RESULTS COUNT ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredDonors.length} of ${allDonors.length} donors',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (searchQuery.isNotEmpty ||
                        selectedBloodGroup != null ||
                        showAvailableOnly)
                      TextButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                            selectedBloodGroup = null;
                            showAvailableOnly = false;
                          });
                        },
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── DONOR LIST ────────────────────────────────
              Expanded(
                child: filteredDonors.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDonors.length,
                        itemBuilder: (context, index) {
                          return _donorCard(filteredDonors[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HELPER: _emptyState ───────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No donors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: const Text(
              'Clear Filters',
              style: TextStyle(color: AppColors.primary),
            ),
            onPressed: () {
              searchController.clear();
              setState(() {
                searchQuery = '';
                selectedBloodGroup = null;
                showAvailableOnly = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── HELPER: _donorCard ────────────────────────────────────────
  Widget _donorCard(Donor donor) {
    bool isAvailable = donor.isAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isAvailable ? AppColors.available : Colors.red,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isAvailable
                          ? AppColors.available.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      child: Text(
                        donor.firstLetter,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? AppColors.available : Colors.red,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.available : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donor.age} yrs • ${donor.gender}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            donor.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donor.bloodGroup,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleAvailability(donor),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.available.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAvailable ? AppColors.available : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: isAvailable ? AppColors.available : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: isAvailable
                                ? AppColors.available
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.touch_app,
                          size: 12,
                          color: isAvailable ? AppColors.available : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🩸 ${donor.totalDonations} donations',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  'Last donated: ${donor.lastDonation}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    label: const Text(
                      'View Profile',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorDetailScreen(donor: donor),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.phone,
                    color: AppColors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Call',
                    style: TextStyle(color: AppColors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable
                        ? AppColors.primary
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isAvailable
                      ? () {
                          CallHelper.makeCall(context, donor.phone);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
