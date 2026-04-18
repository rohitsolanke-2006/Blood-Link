// create_request_screen.dart
// CHANGES:
// - Replaced StorageHelper.saveRequest() with FirestoreService.createRequest()
// - Added createdBy field (current user's uid)
// - Request is now saved to Firestore (visible to ALL users in real-time!)

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/blood_request.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final patientNameController = TextEditingController();
  final hospitalController = TextEditingController();
  final contactController = TextEditingController();
  final unitsController = TextEditingController();
  final notesController = TextEditingController();

  String? _selectedBloodGroup;
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  String _urgency = 'urgent';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Create Blood Request',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── URGENCY BANNER ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please fill accurate information. This helps donors reach the right person.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _sectionLabel('Patient Information'),
              const SizedBox(height: 12),

              TextFormField(
                controller: patientNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Patient Name',
                  hint: 'Enter patient full name',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: hospitalController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Hospital Name & Address',
                  hint: 'e.g. Ruby Hall Clinic, Pune',
                  icon: Icons.local_hospital_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hospital name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: 'Contact Number',
                  hint: 'Enter 10-digit number',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (value.length != 10) {
                    return 'Must be 10 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              _sectionLabel('Blood Details'),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: _inputDecoration(
                  label: 'Blood Group Required',
                  hint: 'Select blood group',
                  icon: Icons.bloodtype,
                ),
                items: _bloodGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodGroup = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select blood group';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: 'Units Required',
                  hint: 'e.g. 2',
                  icon: Icons.water_drop_outlined,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter units required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              _sectionLabel('Urgency Level'),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Urgent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      subtitle: const Text('Need blood within 24 hours'),
                      value: 'urgent',
                      groupValue: _urgency,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _urgency = value!;
                        });
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    RadioListTile<String>(
                      title: const Text(
                        'Normal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Need blood within 2-3 days'),
                      value: 'normal',
                      groupValue: _urgency,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _urgency = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Additional Notes (Optional)'),
              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Notes',
                  hint: 'Any special requirements or details...',
                  icon: Icons.note_outlined,
                ),
              ),

              const SizedBox(height: 32),

              // ── SUBMIT BUTTON ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: AppColors.white),
                  label: const Text(
                    'SUBMIT REQUEST',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );

                      try {
                        // Create BloodRequest object from form data
                        final request = BloodRequest(
                          id: '',
                          // Firestore will auto-generate the ID
                          patientName: patientNameController.text,
                          hospital: hospitalController.text,
                          bloodGroup: _selectedBloodGroup!,
                          contact: contactController.text,
                          urgency: _urgency,
                          units: unitsController.text,
                          notes: notesController.text,
                          location: 'Pune, Maharashtra',
                          timeAgo: 'Just now',
                          status: 'active',
                          createdBy: AuthService.getCurrentUid() ?? '',
                          // createdBy = who created this request
                        );

                        // ── SAVE TO FIRESTORE ──────────────────
                        // This saves the request to Firebase cloud
                        // ALL users will see it instantly on their feed!
                        await FirestoreService.createRequest(request);

                        if (!mounted) return;
                        Navigator.pop(context); // Close spinner

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request submitted successfully! ✅'),
                            backgroundColor: AppColors.available,
                          ),
                        );

                        _clearForm();
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  void _clearForm() {
    patientNameController.clear();
    hospitalController.clear();
    contactController.clear();
    unitsController.clear();
    notesController.clear();
    setState(() {
      _selectedBloodGroup = null;
      _urgency = 'urgent';
    });
  }
}
