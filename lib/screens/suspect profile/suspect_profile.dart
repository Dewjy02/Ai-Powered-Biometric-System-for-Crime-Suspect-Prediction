import 'dart:convert';
import 'dart:typed_data'; 

import 'package:bio_metric_system/model/citizen_model.dart';
import 'package:bio_metric_system/screens/suspect%20profile/suspect_profile_card.dart';
import 'package:bio_metric_system/utilites/colors.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bio_metric_system/model/match_result_model.dart';

class SuspectProfile extends StatefulWidget {
  const SuspectProfile({super.key});

  @override
  State<SuspectProfile> createState() => _SuspectProfileState();
}

class _SuspectProfileState extends State<SuspectProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  Future<Citizen?>? _searchResultFuture;

  late Stream<List<MatchResultModel>> _allSuspectsStream;

  @override
  void initState() {
    super.initState();
    _fetchAllSuspectsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAllSuspectsStream() {
    _allSuspectsStream = _firestore.collectionGroup("suspects").snapshots().map(
      (snapshot) {
        final Map<String, MatchResultModel> uniqueSuspects = {};

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final nic = data["nic"] ?? "";

          if (nic.isNotEmpty && !uniqueSuspects.containsKey(nic)) {
            uniqueSuspects[nic] = MatchResultModel(
              nic: nic,
              name: data["name"] ?? "",
              passportId: data["passportId"] ?? "",
              profileUrl: data["profileUrl"] ?? "",
              score: 0,
            );
          }
        }

        return uniqueSuspects.values.toList();
      },
    );
  }

  void _searchByNic() {
    final nic = _searchController.text.trim();
    if (nic.isNotEmpty) {
      setState(() {
        _searchResultFuture = _fetchCitizenByNic(nic);
      });
    }
  }

  Future<Citizen?> _fetchCitizenByNic(String nic) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('citizens')
          .doc(nic)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return Citizen(
          nic: nic,
          name: data['name'] ?? 'Unknown',
          passportId: int.tryParse(data['passportId'] ?? '') ?? 0,
          profileUrl: data['profile_image'] ?? '',
          dateOfBirth: data['dateOfBirth'] ?? 'N/A',
          address: data['address'] ?? 'N/A',
          mobileNumber: int.tryParse(data['contact'] ?? '') ?? 0,
          fingerPrintId: data['fingerprint_image'] ?? '',
          fingerPrintBase64: data['fingerprint_image'] ?? '',
        );
      } else {
        debugPrint("No citizen found with NIC: $nic");
      }
    } catch (e) {
      debugPrint("Error fetching citizen: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                
                onSubmitted: (value) => _searchByNic(),
                trailing: [
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _searchByNic,
                  ),
                ],
              ),
            ),
            if (_searchResultFuture != null)
              FutureBuilder<Citizen?>(
                future: _searchResultFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return SuspectProfileCard(citizen: snapshot.data!);
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Citizen not found.",
                          style: TextStyle(color: kWhite, fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
          const Divider(),


            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "All Suspects",
                style: TextStyle(
                  color: Colors.black, 
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<MatchResultModel>>(
                stream: _allSuspectsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Error fetching suspects.\n${snapshot.error}",
                          style: TextStyle(color: kWhite),
                        ),
                      ),
                    );
                  }
                  final matches = snapshot.data;
                  if (matches == null || matches.isEmpty) {
                    return Center(
                      child: Text(
                        "No suspects found",
                        style: TextStyle(fontSize: 18, color: kWhite),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      Uint8List? imageBytes;

                      try {
                        if (match.profileUrl.isNotEmpty) {
                          imageBytes = base64Decode(match.profileUrl);
                        }
                      } catch (e) {
                        debugPrint("Invalid Base64 in list: $e");
                        imageBytes = null;
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (imageBytes != null && imageBytes.isNotEmpty)
                                    ? MemoryImage(imageBytes)
                                    : null,
                            child: (imageBytes == null || imageBytes.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            match.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("NIC: ${match.nic}"),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            _searchController.text = match.nic;
                            _searchByNic();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}