// firestore_service.dart
// This file handles ALL database operations with Cloud Firestore
// Replaces StorageHelper for requests, users, and donors
//
// WHAT IS FIRESTORE?
// Think of it like Google Sheets on steroids:
// - "Collections" = Sheets (e.g., 'users' sheet, 'requests' sheet)
// - "Documents" = Rows in a sheet (e.g., one user, one request)
// - Each document has fields like name, email, bloodGroup etc.
//
// THE MAGIC: REAL-TIME UPDATES
// When we use .snapshots() instead of .get(), Firestore sends us
// updates INSTANTLY whenever data changes — like a live WhatsApp
// group where everyone sees new messages immediately!
// This is called a "Stream" — a pipe that keeps sending new data.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_request.dart';
import '../models/donor.dart';

class FirestoreService {

  // ── FIRESTORE INSTANCE ─────────────────────────────────────────
  // Single reference to Firestore database
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── COLLECTION REFERENCES ──────────────────────────────────────
  // These are like "pointers" to our sheets in Firestore
  static final CollectionReference _usersCollection =
      _db.collection('users');
  // 'users' = name of the collection in Firestore

  static final CollectionReference _requestsCollection =
      _db.collection('requests');

  // ═══════════════════════════════════════════════════════════════
  //  USER / PROFILE FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  // ── CREATE USER PROFILE ────────────────────────────────────────
  // Called after registration — saves user details to Firestore
  // uid = unique user ID from Firebase Auth (used as document ID)
  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String bloodGroup,
    required String age,
  }) async {
    // .doc(uid) = create/access document with this specific ID
    // .set() = write data to that document (creates if doesn't exist)
    await _usersCollection.doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'age': age,
      'gender': 'Not set',
      'isAvailable': true,
      // New users are available by default
      'totalDonations': 0,
      'lastDonation': 'Never',
      'fcmToken': '',
      // FCM token will be saved later for push notifications
      'createdAt': FieldValue.serverTimestamp(),
      // serverTimestamp() = Firebase server's time (more accurate)
    });
  }

  // ── GET USER PROFILE ───────────────────────────────────────────
  // Fetches one user's data from Firestore
  // Returns a Map with all fields (name, email, phone, etc.)
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    // .doc(uid).get() = fetch one specific document
    final doc = await _usersCollection.doc(uid).get();

    if (doc.exists) {
      // doc.data() returns the document's data as a Map
      return doc.data() as Map<String, dynamic>;
    }
    return null;
    // Returns null if user document doesn't exist
  }

  // ── UPDATE USER PROFILE ────────────────────────────────────────
  // Updates specific fields of user's profile
  // Only changes the fields you pass — doesn't erase others
  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    // .update() = change only specified fields
    // Unlike .set(), it doesn't overwrite the entire document
    await _usersCollection.doc(uid).update(data);
  }

  // ── UPDATE AVAILABILITY ────────────────────────────────────────
  // Toggles donor availability (available/unavailable)
  static Future<void> updateAvailability(
      String uid, bool isAvailable) async {
    await _usersCollection.doc(uid).update({
      'isAvailable': isAvailable,
    });
  }

  // ── SAVE FCM TOKEN ─────────────────────────────────────────────
  // Saves the push notification token for this user
  // This token is needed to send notifications to this specific phone
  static Future<void> saveFcmToken(String uid, String token) async {
    await _usersCollection.doc(uid).update({
      'fcmToken': token,
    });
  }

  // ── GET ALL DONORS (REAL-TIME STREAM) ──────────────────────────
  // Returns a STREAM of all registered users as Donor objects
  // Stream = live data feed that updates automatically
  // When any user changes their availability, all listeners get updated
  static Stream<List<Donor>> getAllDonors() {
    // .snapshots() = returns a Stream (live updates)
    // .map() = transforms each snapshot into a List<Donor>
    return _usersCollection.snapshots().map((snapshot) {
      // snapshot.docs = list of all documents in 'users' collection
      return snapshot.docs.map((doc) {
        // Convert each Firestore document to a Donor object
        final data = doc.data() as Map<String, dynamic>;
        return Donor(
          id: doc.id,
          // doc.id = the document ID (which is the user's uid)
          name: data['name'] ?? '',
          age: int.tryParse(data['age']?.toString() ?? '0') ?? 0,
          gender: data['gender'] ?? 'Not set',
          bloodGroup: data['bloodGroup'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          location: data['location'] ?? 'Pune, Maharashtra',
          isAvailable: data['isAvailable'] ?? true,
          lastDonation: data['lastDonation'] ?? 'Never',
          totalDonations: data['totalDonations'] ?? 0,
        );
      }).toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  //  BLOOD REQUEST FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  // ── CREATE REQUEST ─────────────────────────────────────────────
  // Adds a new blood request to Firestore
  // .add() = Firebase auto-generates a unique document ID
  static Future<void> createRequest(BloodRequest request) async {
    await _requestsCollection.add(request.toFirestore());
    // toFirestore() converts BloodRequest object to Map
    // which Firestore can store
  }

  // ── GET ALL REQUESTS (REAL-TIME STREAM) ────────────────────────
  // Returns live stream of all blood requests
  // Sorted by creation time — newest first
  // When anyone creates a new request, ALL users see it instantly!
  static Stream<List<BloodRequest>> getAllRequests() {
    return _requestsCollection
        .orderBy('createdAt', descending: true)
        // orderBy = sort results
        // descending: true = newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BloodRequest.fromFirestore(doc.id, data);
        // fromFirestore() creates BloodRequest from Firestore data
        // doc.id = the auto-generated document ID
      }).toList();
    });
  }

  // ── UPDATE REQUEST STATUS ──────────────────────────────────────
  // Changes request status: active → fulfilled → expired
  static Future<void> updateRequestStatus(
      String requestId, String newStatus) async {
    await _requestsCollection.doc(requestId).update({
      'status': newStatus,
    });
  }

  // ── DELETE REQUEST ─────────────────────────────────────────────
  static Future<void> deleteRequest(String requestId) async {
    await _requestsCollection.doc(requestId).delete();
  }

  // ═══════════════════════════════════════════════════════════════
  //  DONATION HISTORY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  // ── ADD DONATION RECORD ────────────────────────────────────────
  // Saves a donation record under the user's sub-collection
  // Sub-collection = a collection inside a document
  // users/{uid}/donations/{donationId}
  static Future<void> addDonation(
      String uid, Map<String, dynamic> donation) async {
    await _usersCollection
        .doc(uid)
        .collection('donations')
        // .collection() inside a document = sub-collection
        .add(donation);

    // Also update the user's total donation count
    await _usersCollection.doc(uid).update({
      'totalDonations': FieldValue.increment(1),
      // FieldValue.increment(1) = add 1 to current value
      // Firebase does this on the server — no need to read first!
      'lastDonation': donation['date'] ?? 'Recently',
    });
  }

  // ── GET DONATION HISTORY ───────────────────────────────────────
  // Fetches all past donations for a specific user
  static Future<List<Map<String, dynamic>>> getDonationHistory(
      String uid) async {
    final snapshot = await _usersCollection
        .doc(uid)
        .collection('donations')
        .orderBy('createdAt', descending: true)
        .get();
    // .get() = one-time fetch (not real-time)

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
