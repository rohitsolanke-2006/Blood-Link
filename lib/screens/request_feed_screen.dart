// request_feed_screen.dart
// CHANGES:
// - Replaced sampleData() + StorageHelper with FirestoreService real-time Stream
// - Uses StreamBuilder for automatic live updates
// - When ANY user creates a request, it appears on ALL feeds instantly!
// - Status updates are saved to Firestore (visible to everyone)
// - Kept all search, filter chips, urgent toggle, and card UI exactly same

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/blood_request.dart';
import '../services/firestore_service.dart';
import '../utils/call_helper.dart';

class RequestFeedScreen extends StatefulWidget {
  const RequestFeedScreen({super.key});

  @override
  State<RequestFeedScreen> createState() => _RequestFeedScreenState();
}

class _RequestFeedScreenState extends State<RequestFeedScreen> {
  // Filter state — same as before
  String searchQuery = '';
  String? selectedBloodGroup;
  bool showUrgentOnly = false;
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
  // Same filter logic as before — works on the live data from Stream
  List<BloodRequest> _applyFilters(List<BloodRequest> allRequests) {
    List<BloodRequest> result = allRequests;

    if (searchQuery.isNotEmpty) {
      result = result.where((r) {
        return r.patientName.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            r.hospital.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectedBloodGroup != null) {
      result = result.where((r) {
        return r.bloodGroup == selectedBloodGroup;
      }).toList();
    }

    if (showUrgentOnly) {
      result = result.where((r) => r.isUrgent).toList();
    }

    return result;
  }

  // ── UPDATE REQUEST STATUS ─────────────────────────────────────
  // Now saves to Firestore — change is visible to ALL users
  void _updateStatus(String requestId, String newStatus) async {
    await FirestoreService.updateRequestStatus(requestId, newStatus);
    // No need to call setState — StreamBuilder auto-updates!
  }

  // ── SHOW STATUS DIALOG ────────────────────────────────────────
  void _showStatusDialog(BuildContext context, BloodRequest request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Update Request Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Patient: ${request.patientName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              _statusOption(
                context: context,
                label: 'Active',
                subtitle: 'Still looking for donors',
                color: AppColors.available,
                icon: Icons.radio_button_checked,
                isSelected: request.status == 'active',
                onTap: () {
                  _updateStatus(request.id, 'active');
                  Navigator.pop(context);
                  _showStatusSnackbar('Request marked as Active');
                },
              ),
              const SizedBox(height: 8),
              _statusOption(
                context: context,
                label: 'Fulfilled',
                subtitle: 'Blood requirement met',
                color: Colors.blue,
                icon: Icons.check_circle_outline,
                isSelected: request.status == 'fulfilled',
                onTap: () {
                  _updateStatus(request.id, 'fulfilled');
                  Navigator.pop(context);
                  _showStatusSnackbar('Request marked as Fulfilled ✅');
                },
              ),
              const SizedBox(height: 8),
              _statusOption(
                context: context,
                label: 'Expired',
                subtitle: 'Request no longer needed',
                color: Colors.grey,
                icon: Icons.cancel_outlined,
                isSelected: request.status == 'expired',
                onTap: () {
                  _updateStatus(request.id, 'expired');
                  Navigator.pop(context);
                  _showStatusSnackbar('Request marked as Expired');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _statusOption({
    required BuildContext context,
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showStatusSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.available;
      case 'fulfilled':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default:
        return AppColors.available;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return '● Active';
      case 'fulfilled':
        return '✓ Fulfilled';
      case 'expired':
        return '✕ Expired';
      default:
        return '● Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Blood Requests',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'New Request',
          style: TextStyle(color: AppColors.white),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/create-request');
        },
      ),

      // ── STREAMBUILDER ─────────────────────────────────────────
      // StreamBuilder listens to FirestoreService.getAllRequests()
      // Whenever data changes in Firestore, this auto-rebuilds!
      // No need for manual refresh — it's REAL-TIME!
      body: StreamBuilder<List<BloodRequest>>(
        stream: FirestoreService.getAllRequests(),
        // stream = the live data pipe from Firestore
        builder: (context, snapshot) {
          // ── LOADING STATE ─────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── ERROR STATE ───────────────────────────────────
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // ── DATA RECEIVED ─────────────────────────────────
          final allRequests = snapshot.data ?? [];
          final filteredRequests = _applyFilters(allRequests);

          return Column(
            children: [
              // ── SEARCH + FILTER SECTION ─────────────────────
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
                        hintText: 'Search by patient or hospital...',
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
                              Icons.emergency,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Show Urgent Only',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: showUrgentOnly,
                          onChanged: (value) {
                            setState(() {
                              showUrgentOnly = value;
                            });
                          },
                          activeThumbColor: AppColors.primary,
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
                      'Showing ${filteredRequests.length} of ${allRequests.length} requests',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    if (searchQuery.isNotEmpty ||
                        selectedBloodGroup != null ||
                        showUrgentOnly)
                      TextButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                            selectedBloodGroup = null;
                            showUrgentOnly = false;
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

              // ── LIST ──────────────────────────────────────
              Expanded(
                child: filteredRequests.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          return _requestCard(filteredRequests[index]);
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
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No requests found',
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
        ],
      ),
    );
  }

  // ── HELPER: _requestCard ──────────────────────────────────────
  Widget _requestCard(BloodRequest request) {
    bool isUrgent = request.urgency == 'urgent';
    Color statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: request.status == 'expired' ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP ROW ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.bloodGroup,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (isUrgent && request.status == 'active') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: AppColors.primary,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        request.timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                request.patientName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.hospital,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    request.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${request.units} unit(s) needed',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── STATUS BADGE ────────────────────────────
              GestureDetector(
                onTap: () => _showStatusDialog(context, request),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _statusLabel(request.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit, size: 12, color: statusColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── ACTION BUTTONS ──────────────────────────
              if (request.status == 'active')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'I Can Donate',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contacting for ${request.patientName}...',
                              ),
                              backgroundColor: AppColors.available,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      label: const Text(
                        'Call',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        CallHelper.makeCall(context, request.contact);
                      },
                    ),
                  ],
                ),

              if (request.status != 'active')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    request.status == 'fulfilled'
                        ? '✅ Blood requirement has been fulfilled'
                        : '⏰ This request has expired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
