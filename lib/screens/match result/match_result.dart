import 'package:bio_metric_system/model/match_result_model.dart';
import 'package:bio_metric_system/screens/suspect%20profile/suspect_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_result_card.dart';
import 'package:bio_metric_system/utilites/colors.dart';
import 'package:bio_metric_system/model/citizen_model.dart';

class MatchResult extends StatefulWidget {
  final Function(String)? onViewProfile;
  const MatchResult({super.key, this.onViewProfile});

  @override
  State<MatchResult> createState() => _MatchResultState();
}

class _MatchResultState extends State<MatchResult> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showCitizenProfileDialog(BuildContext context, String nic) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Center(child: Text("Suspect Profile")),
          contentPadding: const EdgeInsets.all(12.0),
          content: _ProfileDialogBody(
            nic: nic,
            firestore: _firestore,
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: kMainColor.withOpacity(0.6),
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection("Meta").doc("caseCounter").snapshots(),
          builder: (context, counterSnapshot) {
            if (counterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!counterSnapshot.hasData || !counterSnapshot.data!.exists) {
              return const Center(child: Text("System Meta data missing"));
            }

            final lastCaseNum = counterSnapshot.data!.get("lastCase");
            if (lastCaseNum == null) {
              return const Center(child: Text("No cases processed yet"));
            }

            final caseId = "case ${lastCaseNum.toString().padLeft(2, '0')}";

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("Cases")
                  .doc(caseId)
                  .collection("suspects")
                  .snapshots(), 
              builder: (context, suspectsSnapshot) {
                if (suspectsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = suspectsSnapshot.data?.docs;
                if (docs == null || docs.isEmpty) {
                  return const Center(
                    child: Text("Waiting for matches...", style: TextStyle(fontSize: 18)),
                  );
                }

                final matches = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return MatchResultModel(
                    nic: data["nic"] ?? "",
                    name: data["name"] ?? "",
                    passportId: data["passportId"] ?? "",
                    profileUrl: data["profileUrl"] ?? "",
                    score: (data["score"] ?? 0).toDouble(),
                  );
                }).toList();

                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return MatchResultCard(
                      name: match.name,
                      matchPercentage: match.score * 100,
                      matchTime: DateTime.now(), 
                      profileImageUrl: match.profileUrl,
                      onViewProfile: () {
                        _showCitizenProfileDialog(context, match.nic);
                        if (widget.onViewProfile != null) {
                          widget.onViewProfile!(match.nic);
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDialogBody extends StatefulWidget {
  final String nic;
  final FirebaseFirestore firestore;

  const _ProfileDialogBody({
    required this.nic,
    required this.firestore,
  });

  @override
  State<_ProfileDialogBody> createState() => _ProfileDialogBodyState();
}

class _ProfileDialogBodyState extends State<_ProfileDialogBody> {
  Citizen? _citizen;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCitizenProfile();
  }

  Future<void> _fetchCitizenProfile() async {
    try {
      final doc = await widget.firestore
          .collection("citizens")
          .doc(widget.nic)
          .get();

      if (!doc.exists) {
        throw Exception("Profile not found");
      }

      final data = doc.data() as Map<String, dynamic>;
      final citizen = Citizen(
        nic: widget.nic,
        name: data['name'] ?? '',
        passportId: int.tryParse(data['passportId'] ?? '') ?? 10,
        address: data['address'] ?? '',
        mobileNumber: int.tryParse(data['contact'] ?? '') ?? 0,
        profileUrl: data['profile_image'] ?? '',
        fingerPrintId: data['fingerprint_image'] ?? '',
        dateOfBirth: data['dateOfBirth'] ?? '',
        fingerPrintBase64: data['fingerprint_base64'] ?? '',
      );

      if (mounted) {
        setState(() {
          _citizen = citizen;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Text(_error!);
    }

    if (_citizen != null) {
      return SuspectProfileCard(citizen: _citizen!);
    }

    return const Text("An unexpected error occurred.");
  }
}