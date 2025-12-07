import 'dart:convert';
import 'dart:typed_data';
import 'package:bio_metric_system/model/citizen_model.dart'; // We need this
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddCitizen extends StatefulWidget {
  final Citizen? citizenToEdit;
  const AddCitizen({super.key, this.citizenToEdit});

  @override
  State<AddCitizen> createState() => _AddCitizenState();
}

class _AddCitizenState extends State<AddCitizen> {
  Uint8List? profileImageBytes;
  Uint8List? fingerprintImageBytes;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nicController = TextEditingController();
  final TextEditingController passportIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController mobileNumController = TextEditingController();

  String? _existingProfileBase64;
  String? _existingFingerprintBase64;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.citizenToEdit != null) {
      _isEditMode = true;
      final citizen = widget.citizenToEdit!;

      nicController.text = citizen.nic;
      passportIdController.text = citizen.passportId.toString();
      nameController.text = citizen.name;
      dateOfBirthController.text = citizen.dateOfBirth;
      addressController.text = citizen.address;
      mobileNumController.text = citizen.mobileNumber.toString();

      _existingProfileBase64 = citizen.profileUrl;
      _existingFingerprintBase64 = citizen.fingerPrintId;
    }
  }

  Future<void> pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        profileImageBytes = result.files.first.bytes;
        _existingProfileBase64 = null;
      });
    }
  }

  Future<void> pickFingerprintImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        fingerprintImageBytes = result.files.first.bytes;
        _existingFingerprintBase64 = null;
      });
    }
  }

  Uint8List? _safeBase64Decode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (profileImageBytes == null && _existingProfileBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image is required!")),
      );
      return;
    }
    if (fingerprintImageBytes == null && _existingFingerprintBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fingerprint image is required!")),
      );
      return;
    }

    String? profileBase64 = profileImageBytes != null
        ? base64Encode(profileImageBytes!)
        : _existingProfileBase64;
    
    String? fingerprintBase64 = fingerprintImageBytes != null
        ? base64Encode(fingerprintImageBytes!)
        : _existingFingerprintBase64;

    await FirebaseFirestore.instance
        .collection('citizens')
        .doc(nicController.text.trim())
        .set({
          'name': nameController.text.trim(),
          'dateOfBirth': dateOfBirthController.text.trim(),
          'passportId': passportIdController.text.trim(),
          'address': addressController.text.trim(),
          'contact': mobileNumController.text.trim(),
          'profile_image': profileBase64,
          'fingerprint_image': fingerprintBase64,
          if (!_isEditMode) 'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text(_isEditMode
            ? "Data Updated Successfully!"
            : "Data Stored Successfully!")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final initialProfileImg =
        profileImageBytes ?? _safeBase64Decode(_existingProfileBase64);
    final initialFingerprintImg = fingerprintImageBytes ??
        _safeBase64Decode(_existingFingerprintBase64);

    return SizedBox(
      child: SingleChildScrollView(
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: 400, 
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isEditMode ? "Edit Citizen" : "Who's new...",
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickProfileImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: kMainTextColor,
                        backgroundImage: initialProfileImg != null
                            ? MemoryImage(initialProfileImg)
                            : null,
                        child: initialProfileImg == null
                            ? Icon(Icons.add_a_photo, size: 30, color: kWhite)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: nicController,
                      enabled: !_isEditMode,
                      decoration: InputDecoration(
                        labelText: "NIC",
                        border: const OutlineInputBorder(),
                        filled: _isEditMode, 
                        fillColor: _isEditMode ? Colors.grey.shade200 : null,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "NIC is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passportIdController,
                      decoration: const InputDecoration(
                        labelText: "Passport ID",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Passport is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Full Name is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth (YYYY-MM-DD)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Date of Birth is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: "Address",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Address is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: mobileNumController,
                      decoration: const InputDecoration(
                        labelText: "Contact Number",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? "Contact Number is required"
                          : null,
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: pickFingerprintImage,
                      child: Container(
                        height: initialFingerprintImg != null ? 140 : 70,
                        width: initialFingerprintImg != null
                            ? 140
                            : double.infinity,
                        decoration: BoxDecoration(
                          color: kMainTextColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kMainTextColor),
                        ),
                        child: initialFingerprintImg == null
                            ? Icon(Icons.fingerprint, size: 40, color: kWhite)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  initialFingerprintImg,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            saveUser();
                          },
                          child: Text(
                            _isEditMode ? "Update" : "Save",
                            style: TextStyle(color: kMainTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}