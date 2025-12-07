import 'dart:convert';
import 'dart:typed_data';
import 'package:bio_metric_system/model/citizen_model.dart'; 
import 'package:bio_metric_system/screens/user%20data%20management/add_citizen.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/utilites/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDataManagemet extends StatefulWidget {
  const UserDataManagemet({super.key});

  @override
  State<UserDataManagemet> createState() => _UserDataManagemetState();
}

class _UserDataManagemetState extends State<UserDataManagemet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCitizenDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddCitizen(citizenToEdit: null);
      },
    );
  }

  void _showEditCitizenDialog(Citizen citizen) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCitizen(citizenToEdit: citizen);
      },
    );
  }

  void _showDeleteConfirmation(String nic, String name) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: Text("Are you sure you want to delete $name (NIC: $nic)?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
              onPressed: () {
                _deleteCitizen(nic);
                Navigator.of(dialogContext).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCitizen(String nic) async {
    try {
      await _firestore.collection('citizens').doc(nic).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Citizen deleted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete citizen: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Uint8List? _safeBase64Decode(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint("Invalid Base64 string: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(appPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add and manage individuals's biometric data",
            style: TextStyle(color: kSecTextColor, fontSize: 17),
          ),
          SizedBox(height: appPadding / 2),
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: "Search by name or NIC...",
                  leading: Icon(Icons.search, size: 25, color: kMainTextColor),
                  backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 194, 221, 244)),
                  textStyle: MaterialStateProperty.all(
                      const TextStyle(color: Colors.black, fontSize: 16)),
                  hintStyle:
                      MaterialStateProperty.all(TextStyle(color: kMainTextColor)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8)),
                  elevation: MaterialStateProperty.all(4),
                ),
              ),
              SizedBox(width: appPadding),
              ElevatedButton.icon(
                onPressed: _showAddCitizenDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 38, 116, 233),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                icon: Icon(Icons.add, size: 24, color: kWhite),
                label: Text(
                  "Add New",
                  style: TextStyle(color: kWhite, fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: appPadding),
          const Divider(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('citizens').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No citizens found."));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final nic = doc.id.toLowerCase();
                  return name.contains(_searchQuery) ||
                      nic.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No citizens match your search."));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final citizen = Citizen(
                      nic: doc.id,
                      name: data['name'] ?? '',
                      passportId:
                          int.tryParse(data['passportId'] ?? '0') ?? 0,
                      profileUrl: data['profile_image'] ?? '',
                      dateOfBirth: data['dateOfBirth'] ?? 'N/A',
                      address: data['address'] ?? 'N/A',
                      mobileNumber: int.tryParse(data['contact'] ?? '0') ?? 0,
                      fingerPrintId: data['fingerprint_image'] ?? '',
                      fingerPrintBase64: data['fingerprint_image'] ?? '',
                    );

                    final imageBytes = _safeBase64Decode(citizen.profileUrl);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (imageBytes != null)
                              ? MemoryImage(imageBytes)
                              : null,
                          child: (imageBytes == null)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(citizen.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("NIC: ${citizen.nic}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditCitizenDialog(citizen);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(
                                    citizen.nic, citizen.name);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}