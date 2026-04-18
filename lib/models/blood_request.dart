// blood_request.dart
// Blueprint for a Blood Request
// Updated to work with both Firestore and local Maps
//
// CHANGES FROM PREVIOUS VERSION:
// - Added 'createdBy' field (stores uid of who created the request)
// - Added fromFirestore() factory constructor
// - Added toFirestore() method for saving to Firestore
// - Removed sampleData() — data now comes from real database!

import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {

  final String id;
  final String patientName;
  final String hospital;
  final String bloodGroup;
  final String contact;
  final String urgency;
  final String units;
  final String notes;
  final String location;
  final String timeAgo;
  String status;
  final DateTime createdAt;
  final String createdBy;
  // createdBy = uid of the user who created this request
  // Used to show "Your request" vs someone else's request

  BloodRequest({
    required this.id,
    required this.patientName,
    required this.hospital,
    required this.bloodGroup,
    required this.contact,
    required this.urgency,
    required this.units,
    required this.location,
    required this.timeAgo,
    this.notes = '',
    this.status = 'active',
    this.createdBy = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── toMap() ─────────────────────────────────────────────────────
  // Converts BloodRequest to Map (for local storage backward compat)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'hospital': hospital,
      'bloodGroup': bloodGroup,
      'contact': contact,
      'urgency': urgency,
      'units': units,
      'notes': notes,
      'location': location,
      'timeAgo': timeAgo,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ── fromMap() ───────────────────────────────────────────────────
  // Creates BloodRequest from a Map (backward compat with local storage)
  factory BloodRequest.fromMap(Map<String, dynamic> map) {
    return BloodRequest(
      id: map['id'] ?? '',
      patientName: map['patientName'] ?? '',
      hospital: map['hospital'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      contact: map['contact'] ?? '',
      urgency: map['urgency'] ?? 'normal',
      units: map['units'] ?? '1',
      notes: map['notes'] ?? '',
      location: map['location'] ?? '',
      timeAgo: map['timeAgo'] ?? '',
      status: map['status'] ?? 'active',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // ── toFirestore() ───────────────────────────────────────────────
  // Converts BloodRequest to Map for saving to Firestore
  // Uses FieldValue.serverTimestamp() for accurate server time
  Map<String, dynamic> toFirestore() {
    return {
      'patientName': patientName,
      'hospital': hospital,
      'bloodGroup': bloodGroup,
      'contact': contact,
      'urgency': urgency,
      'units': units,
      'notes': notes,
      'location': location,
      'status': status,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      // serverTimestamp() = Firebase server's time
      // More reliable than device time (which could be wrong)
    };
  }

  // ── fromFirestore() ─────────────────────────────────────────────
  // Creates BloodRequest from Firestore document data
  // docId = the auto-generated Firestore document ID
  factory BloodRequest.fromFirestore(
      String docId, Map<String, dynamic> data) {
    // Calculate "time ago" from createdAt timestamp
    String timeAgo = 'Just now';
    if (data['createdAt'] != null) {
      final Timestamp timestamp = data['createdAt'] as Timestamp;
      final DateTime created = timestamp.toDate();
      final Duration diff = DateTime.now().difference(created);

      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays} day(s) ago';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours} hour(s) ago';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes} min ago';
      }
    }

    return BloodRequest(
      id: docId,
      patientName: data['patientName'] ?? '',
      hospital: data['hospital'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      contact: data['contact'] ?? '',
      urgency: data['urgency'] ?? 'normal',
      units: data['units'] ?? '1',
      notes: data['notes'] ?? '',
      location: data['location'] ?? '',
      timeAgo: timeAgo,
      status: data['status'] ?? 'active',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ── GETTERS ────────────────────────────────────────────────────
  bool get isUrgent => urgency == 'urgent';
  bool get isActive => status == 'active';

  String get formattedDate {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }
}
