import 'dart:convert';
import 'dart:typed_data';
import 'package:bio_metric_system/screens/login/sign_in.dart'; 
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileDialog extends StatefulWidget {
  final String uid;
  final String userEmail;
  final Map<String, dynamic> currentUserData;

  const UserProfileDialog({
    super.key,
    required this.uid,
    required this.userEmail,
    required this.currentUserData,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicController;
  late TextEditingController _emailController;
  
  Uint8List? _newImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUserData['name'] ?? '');
    _nicController = TextEditingController(text: widget.currentUserData['nic']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, 
      );
      if (!mounted) return; 
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _newImageBytes = result.files.first.bytes;
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      if (widget.uid == "admin_id") {
         if (!mounted) return;
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin profile is read-only."), backgroundColor: Colors.orange),
        );
        return;
      }
      int? nicAsInt = int.tryParse(_nicController.text.trim());
      
      if (nicAsInt == null) {
        throw Exception("Invalid NIC format. Must be a number.");
      }

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'nic': nicAsInt,
      };

      if (_newImageBytes != null) {
        updateData['profile_image'] = base64Encode(_newImageBytes!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(updateData, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

  @override
  Widget build(BuildContext context) {
    final ImageProvider? imageProvider;
    if (_newImageBytes != null) {
      imageProvider = MemoryImage(_newImageBytes!);
    } else {
      final dbImageBytes = _safeBase64Decode(widget.currentUserData['profile_image']);
      imageProvider = dbImageBytes != null ? MemoryImage(dbImageBytes) : null;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      title: const Center(child: Text("User Profile", style: TextStyle(fontWeight: FontWeight.bold))),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    InkWell(
                      onTap: _pickImage, 
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: false, 
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicController,
                  enabled: false, 
                  decoration: const InputDecoration(
                    labelText: "NIC (Login ID)",
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                    filled: true, 
                    fillColor: Color(0xFFF5F5F5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () async {
                if (FirebaseAuth.instance.currentUser != null) {
                   await FirebaseAuth.instance.signOut();
                }
                
                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignIn()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUploading ? null : _saveProfile,
                  child: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}