// donor.dart
// Blueprint for a Donor
// Updated to work with Firestore — donors are now REAL registered users!
//
// CHANGES FROM PREVIOUS VERSION:
// - Added fromFirestore() factory constructor
// - Removed sampleData() — donors are real users from the database!
// - Kept toMap() and fromMap() for backward compatibility

class Donor {

  final String id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String email;
  final String location;
  bool isAvailable;
  // NOT final — availability can be toggled by user
  final String lastDonation;
  final int totalDonations;

  Donor({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
    required this.email,
    required this.location,
    required this.isAvailable,
    required this.lastDonation,
    required this.totalDonations,
  });

  // ── toMap() ───────────────────────────────────────────────────
  // Converts Donor object → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'phone': phone,
      'email': email,
      'location': location,
      'isAvailable': isAvailable,
      'lastDonation': lastDonation,
      'totalDonations': totalDonations,
    };
  }

  // ── fromMap() ─────────────────────────────────────────────────
  // Converts Map → Donor object
  factory Donor.fromMap(Map<String, dynamic> map) {
    return Donor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Not set',
      bloodGroup: map['bloodGroup'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      location: map['location'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      lastDonation: map['lastDonation'] ?? 'Never',
      totalDonations: map['totalDonations'] ?? 0,
    );
  }

  // ── firstLetter getter ────────────────────────────────────────
  // Returns first letter of name for avatar display
  String get firstLetter =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';
}