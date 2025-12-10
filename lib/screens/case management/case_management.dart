import 'dart:convert';
import 'dart:typed_data';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CaseManagement extends StatefulWidget {
  const CaseManagement({super.key});

  @override
  State<CaseManagement> createState() => _CaseManagementState();
}

class _CaseManagementState extends State<CaseManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _confirmedCasesStream;
  late Stream<DocumentSnapshot> _caseCounterStream;
  late Stream<QuerySnapshot> _closedCasesListStream;

  final TextEditingController _activeSearchController = TextEditingController();
  String _activeSearchQuery = "";
  bool _isActiveSearchVisible = false;

  final TextEditingController _closedSearchController = TextEditingController();
  String _closedSearchQuery = "";
  bool _isClosedSearchVisible = false;

  final Set<String> _expandedCaseIds = {};

  final List<String> _caseTypes = [
    "Theft",
    "Fraud",
    "Assault",
    "Murder",
    "Robbery",
    "Other",
  ];

  final Map<String, String> _selectedCaseTypes = {};

  @override
  void initState() {
    super.initState();
    _confirmedCasesStream = _firestore.collection('ConfirmedCases').snapshots();
    _caseCounterStream =
        _firestore.collection('Meta').doc('caseCounter').snapshots();
    _closedCasesListStream = _firestore
        .collection('ConfirmedCases')
        .orderBy('confirmedAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _activeSearchController.dispose();
    _closedSearchController.dispose();
    super.dispose();
  }

  void _toggleActiveSearchBar() {
    setState(() {
      _isActiveSearchVisible = !_isActiveSearchVisible;
      if (!_isActiveSearchVisible) {
        _activeSearchController.clear();
        _activeSearchQuery = "";
      }
    });
  }

  void _onActiveSearchChanged(String query) {
    setState(() {
      _activeSearchQuery = query.toLowerCase().trim();
    });
  }

  void _toggleClosedSearchBar() {
    setState(() {
      _isClosedSearchVisible = !_isClosedSearchVisible;
      if (!_isClosedSearchVisible) {
        _closedSearchController.clear();
        _closedSearchQuery = "";
      }
    });
  }

  void _onClosedSearchChanged(String query) {
    setState(() {
      _closedSearchQuery = query.toLowerCase().trim();
    });
  }

  Uint8List? _safeBase64Decode(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Future<void> _confirmCase(
    String caseId,
    String caseType,
    Map<String, dynamic> suspectData,
  ) async {
    try {
      await _firestore.collection('ConfirmedCases').add({
        'caseId': caseId,
        'caseType': caseType,
        'suspectName': suspectData['name'],
        'suspectNic': suspectData['nic'],
        'suspectPassport': suspectData['passportId'],
        'suspectProfileUrl': suspectData['profileUrl'],
        'matchScore': suspectData['score'],
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      if (_expandedCaseIds.contains(caseId)) {
        setState(() {
          _expandedCaseIds.remove(caseId);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Case Confirmed & Closed Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showClosedDetails(Map<String, dynamic> data) {
    final imageBytes = _safeBase64Decode(data['suspectProfileUrl']);

    String formattedDate = "Unknown Date";
    if (data['confirmedAt'] != null) {
      Timestamp t = data['confirmedAt'];
      formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(t.toDate());
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 10),
            Text("Case Closed: ${data['caseId'].toString().toUpperCase()}"),
            Text(
              data['caseType'],
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              const Text(
                "Confirmed Culprit",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    imageBytes != null ? MemoryImage(imageBytes) : null,
                child: imageBytes == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 15),
              _buildDetailRow(Icons.person, "Name", data['suspectName']),
              _buildDetailRow(Icons.credit_card, "NIC", data['suspectNic']),
              _buildDetailRow(
                Icons.flight,
                "Passport",
                data['suspectPassport'],
              ),
              _buildDetailRow(
                Icons.analytics,
                "Match Score",
                "${(data['matchScore'] * 100).toStringAsFixed(1)}%",
              ),
              const Divider(),
              _buildDetailRow(Icons.calendar_today, "Closed On", formattedDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Active Pending Cases",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _toggleActiveSearchBar,
                  icon: Icon(
                    _isActiveSearchVisible ? Icons.search_off : Icons.search,
                    color: Colors.black,
                    size: 28,
                  ),
                  tooltip: _isActiveSearchVisible
                      ? "Close Search"
                      : "Search by Case Number",
                ),
              ],
            ),
          ),

          if (_isActiveSearchVisible)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 3, 51, 122),
                      Color.fromARGB(255, 37, 144, 231),
                    ],
                  ),
                ),
                child: TextField(
                  controller: _activeSearchController,
                  onChanged: _onActiveSearchChanged,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Search Case Number(e.g., 1, 10)...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(
                      Icons.folder_open,
                      color: Colors.white,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleActiveSearchBar,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            flex: 3,
            child: StreamBuilder<QuerySnapshot>(
              stream: _confirmedCasesStream,
              builder: (context, confirmedSnapshot) {
                if (confirmedSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Set<String> confirmedCaseIds = confirmedSnapshot
                    .data!
                    .docs
                    .map((doc) => doc['caseId'] as String)
                    .toSet();

                return StreamBuilder<DocumentSnapshot>(
                  stream: _caseCounterStream,
                  builder: (context, counterSnapshot) {
                    if (!counterSnapshot.hasData ||
                        !counterSnapshot.data!.exists) {
                      return const Center(
                        child: Text(
                          "No data.",
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    final int lastCase =
                        (counterSnapshot.data!.data()
                            as Map<String, dynamic>)['lastCase'] ??
                        0;

                    List<String> activeCasesList = [];
                    for (int i = 1; i <= lastCase; i++) {
                      String id = "case ${i.toString().padLeft(2, '0')}";
                      String rawNumber = i.toString();

                      if (!confirmedCaseIds.contains(id)) {
                        bool matchesSearch = true;
                        if (_activeSearchQuery.isNotEmpty) {
                          if (!rawNumber.startsWith(_activeSearchQuery) &&
                              !id.contains(_activeSearchQuery)) {
                            matchesSearch = false;
                          }
                        }

                        if (matchesSearch) {
                          activeCasesList.add(id);
                        }
                      }
                    }

                    if (activeCasesList.isEmpty) {
                      return Center(
                        child: Text(
                          _activeSearchQuery.isEmpty
                              ? "All cases are cleared!"
                              : "No case found matching '$_activeSearchQuery'",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: activeCasesList.length,
                      itemBuilder: (context, index) {
                        final caseId = activeCasesList[index];
                        return _buildActiveCaseCard(caseId, Key(caseId));
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.black, height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recently Closed Cases",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _toggleClosedSearchBar,
                  icon: Icon(
                    _isClosedSearchVisible ? Icons.search_off : Icons.search,
                    color: Colors.black,
                    size: 24,
                  ),
                  tooltip: _isClosedSearchVisible
                      ? "Close Search"
                      : "Search by NIC",
                ),
              ],
            ),
          ),

          if (_isClosedSearchVisible)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _closedSearchController,
                onChanged: _onClosedSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search by Suspect NIC...",
                  prefixIcon: const Icon(Icons.credit_card, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _toggleClosedSearchBar,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: _closedCasesListStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No closed cases.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                if (_closedSearchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nic = (data['suspectNic'] ?? "")
                        .toString()
                        .toLowerCase();
                    return nic.contains(_closedSearchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No NIC found.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildConfirmedCaseCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCaseCard(String caseId, Key key) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 3, 51, 122),
                Color.fromARGB(255, 37, 144, 231),
              ],
            ),
          ),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,

            iconColor: Colors.white,
            collapsedIconColor: Colors.white70,

            // If the ID is in our set, it's expanded
            initiallyExpanded: _expandedCaseIds.contains(caseId),
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedCaseIds.add(caseId);
                } else {
                  _expandedCaseIds.remove(caseId);
                }
              });
            },

            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
              child: const Icon(Icons.folder_open, color: Colors.white),
            ),

            title: Text(
              caseId.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),

            subtitle: Text(
              _selectedCaseTypes[caseId] == null
                  ? "Select Type to Activate Actions"
                  : "Type: ${_selectedCaseTypes[caseId]}",
              style: TextStyle(
                color: _selectedCaseTypes[caseId] == null
                    ? const Color.fromARGB(255, 228, 153, 242)
                    : Colors.greenAccent,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),

            children: [
              Container(
                color: Colors.black.withOpacity(0.1),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          hint: const Text(
                            'Select Case Classification',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          items: _caseTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          value: _selectedCaseTypes[caseId],
                          onChanged: (value) {
                            setState(() {
                              _selectedCaseTypes[caseId] = value!;
                            });
                          },
                          buttonStyleData: ButtonStyleData(
                            height: 50,
                            padding: const EdgeInsets.only(left: 14, right: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            height: 40,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "SUSPECT MATCHES",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('Cases')
                          .doc(caseId)
                          .collection('suspects')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "No suspects found for this case.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final imageBytes = _safeBase64Decode(
                              data['profileUrl'],
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)
                                      : null,
                                  child: imageBytes == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  data['name'] ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "NIC: ${data['nic']}\nMatch Score: ${(data['score'] * 100).toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _selectedCaseTypes[caseId] != null
                                        ? const Color(0xFF03337A)
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: _selectedCaseTypes[caseId] != null
                                      ? () {
                                          _confirmCase(
                                            caseId,
                                            _selectedCaseTypes[caseId]!,
                                            data,
                                          );
                                        }
                                      : null,
                                  child: const Text("Confirm"),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedCaseCard(Map<String, dynamic> data) {
    final imageBytes = _safeBase64Decode(data['suspectProfileUrl']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 3, 51, 122),
                Color.fromARGB(255, 37, 144, 231),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showClosedDetails(data);
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes)
                        : null,
                    child: imageBytes == null
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  ),
                ),
                title: Text(
                  "${data['caseId'].toString().toUpperCase()} - ${data['caseType']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Culprit: ${data['suspectName']}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}